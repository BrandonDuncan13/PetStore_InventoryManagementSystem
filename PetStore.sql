IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'bduncan')
BEGIN
    EXEC ('CREATE DATABASE bduncan');
END
GO

USE bduncan;
GO

-- create the schema 
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name='PetStore') BEGIN
EXEC sp_executesql N'CREATE SCHEMA PetStore';
END
GO

-- identify index fragmentation for a specific database
-- index candidates for rebuild (above 30% rule)
-- index candidates for reorganize (above 5%)
SELECT OBJECT_NAME(ind.OBJECT_ID) AS TableName, 
ind.name AS IndexName, indexstats.index_type_desc AS IndexType, 
indexstats.avg_fragmentation_in_percent,
'ALTER INDEX ' + QUOTENAME(ind.name)  + ' ON ' +QUOTENAME(object_name(ind.object_id)) + 
CASE    WHEN indexstats.avg_fragmentation_in_percent>30 THEN ' REBUILD' 
        WHEN indexstats.avg_fragmentation_in_percent>=5 THEN 'REORGANIZE'
        ELSE NULL END as [SQLQuery]  -- if <5 not required, so no query needed
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats 
INNER JOIN sys.indexes ind ON ind.object_id = indexstats.object_id 
    AND ind.index_id = indexstats.index_id 
WHERE 
--indexstats.avg_fragmentation_in_percent , e.g. >10, you can specify any number in percent 
ind.Name is not null 
ORDER BY indexstats.avg_fragmentation_in_percent DESC

-- normalize to 3NF
-- 1NF
-- Eliminate unneccessary data
-- Group Data -	have each table describe one thing
-- Determine key(s)
-- Eliminate Repeating groups

-- 2NF
-- 1NF achieved
-- all non key columns in each table are dependent on the whole key

-- 3NF
-- 2NF achieved
-- no transitive dependencies

-- here we are creating all the tables for the pet store database 
-- animals table
ALTER TABLE PetStore.AnimalInfo DROP CONSTRAINT IF EXISTS [fkAnimalInfo_Animal]
GO

ALTER TABLE PetStore.AnimalPricing DROP CONSTRAINT IF EXISTS [fkAnimalPricing_Animal]
GO

ALTER TABLE PetStore.AnimalStorage DROP CONSTRAINT IF EXISTS [fkAnimalStorage_Animal]
GO

ALTER TABLE PetStore.PurchasedAnimals DROP CONSTRAINT IF EXISTS [fkPurchasedAnimals_Animal]
GO

DROP TABLE IF EXISTS PetStore.Animal;
GO

-- animal table
CREATE TABLE PetStore.Animal
(
	AnimalId				INT	IDENTITY(1,1)	NOT NULL -- integer value,ID for specific animal
	, AnimalName			VARCHAR(50)			NOT NULL -- animal's name
	, AnimalTypeId			INT					NOT NULL -- dog, cat, fish, bird, etc
	, AnimalBreedId			INT					NOT NULL
	, AnimalGender			CHAR(1)				NOT NULL
)
;
GO
-- primary key animal id
ALTER TABLE PetStore.Animal
	ADD CONSTRAINT pkAnimalId PRIMARY KEY NONCLUSTERED (AnimalId);
GO

-- foreign key animaltype id
ALTER TABLE PetStore.Animal
	ADD CONSTRAINT fkAnimal_AnimalType FOREIGN KEY (AnimalTypeId)
REFERENCES PetStore.AnimalType (AnimalTypeId);
GO

-- foreign key animalbreed id
ALTER TABLE PetStore.Animal
	ADD CONSTRAINT fkAnimal_AnimalBreed FOREIGN KEY (AnimalBreedId)
REFERENCES PetStore.AnimalBreed (AnimalBreedId);
GO

-- select all animals in animal table
CREATE OR ALTER PROC PetStore.GetAllAnimals
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM PetStore.Animal;
END
GO

-- select animal from table by id
CREATE OR ALTER PROC PetStore.GetAnimalById
    @AnimalId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM PetStore.Animal WHERE AnimalId = @AnimalId;
END
GO

-- animal table test the SELECT procs
SELECT 'Testing all SELECT on Animal'
EXEC PetStore.GetAllAnimals
SELECT 'Testing the single SELECT on Animal'
EXEC PetStore.GetAnimalById @animalId = 1;
GO

-- insert animal proc
CREATE OR ALTER PROC PetStore.InsertAnimal
    @AnimalName VARCHAR(50)
    , @AnimalTypeId INT
    , @AnimalBreedId INT
    , @AnimalGender CHAR(1)
AS
BEGIN
	IF EXISTS -- animal type referenced must exist
	(
		SELECT * FROM PetStore.AnimalType
		WHERE AnimalTypeId = @AnimalTypeId
	)
	BEGIN
		IF EXISTS -- animal breed referenced must exist
		(
			SELECT * FROM PetStore.AnimalBreed
			WHERE AnimalBreedId = @AnimalBreedId
		)
		BEGIN
			SET NOCOUNT ON;
			INSERT INTO PetStore.Animal (AnimalName, AnimalTypeId, AnimalBreedId, AnimalGender)
			VALUES (@AnimalName, @AnimalTypeId, @AnimalBreedId, @AnimalGender);
		END
	END
END
GO

SELECT 'Testing the INSERT proc on Animal'
EXEC PetStore.InsertAnimal 'Spudz Mackenzie', 1, 1, 'm';
EXEC PetStore.InsertAnimal 'Garfield', 2, 2, 'm';
EXEC PetStore.InsertAnimal 'Gilbert', 3, 3, 'f';
EXEC PetStore.InsertAnimal 'Tweety', 4, 4, 'm';
EXEC PetStore.InsertAnimal 'Fluffy', 1, 1, 'f';
SELECT * FROM PetStore.Animal;
GO

-- update animal proc
CREATE OR ALTER PROC PetStore.UpdateAnimal
    @AnimalId INT
    , @AnimalName VARCHAR(50)
    , @AnimalTypeId INT
    , @AnimalBreedId INT
    , @AnimalGender CHAR(1)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE PetStore.Animal
    SET AnimalName = @AnimalName, AnimalTypeId = @AnimalTypeId, AnimalBreedId = @AnimalBreedId, AnimalGender = @AnimalGender
    WHERE AnimalId = @AnimalId;
END
GO

-- animal table testing update proc
SELECT 'Testing UPDATE on Animal'
EXEC PetStore.GetAnimalById @animalId = 1;
EXEC PetStore.GetAnimalById @animalId = 2;
EXEC PetStore.UpdateAnimal 1, 'Spudzon McKenzie', 1, 1, 'f';
EXEC PetStore.UpdateAnimal 2, 'Garfield the cat', 2, 3, 'm';
EXEC PetStore.GetAnimalById @animalId = 1;
EXEC PetStore.GetAnimalById @animalId = 2;
SELECT * FROM PetStore.Animal;
GO

-- delete animal proc
CREATE OR ALTER PROC PetStore.DeleteAnimal
    @AnimalId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM PetStore.Animal
    WHERE AnimalId = @AnimalId;
END
GO

-- animal table testing delete proc
SELECT 'Testing DELETE on Animal'
EXEC PetStore.GetAllAnimals;
EXEC PetStore.DeleteAnimal @animalId = 5;
EXEC PetStore.GetAllAnimals;
GO

SELECT * FROM PetStore.Animal;
GO


-- animal type table
ALTER TABLE PetStore.Animal DROP CONSTRAINT IF EXISTS [fkAnimal_AnimalType]
GO

DROP TABLE IF EXISTS PetStore.AnimalType;
GO

CREATE TABLE PetStore.AnimalType
(
	AnimalTypeId	INT IDENTITY(1, 1)  NOT NULL
	, AnimalType	VARCHAR(50)			NULL -- dog, cat, fish, bird, etc.
)
;
GO

-- primary key animaltype id
ALTER TABLE PetStore.AnimalType
	ADD CONSTRAINT pkAnimalTypeId PRIMARY KEY (AnimalTypeId);
GO

-- create a view of animal type table
CREATE OR ALTER VIEW PetStore.vwAnimalType
AS
SELECT
	AnimalTypeId
	, AnimalType
FROM PetStore.AnimalType
GO

-- animal type table insert proc
CREATE OR ALTER PROC PetStore.InsertAnimalType
(
	@animalType VARCHAR(50) NULL -- dog, cat, fish, bird, etc
)
AS
BEGIN
	IF NOT EXISTS -- cannot be a duplicate record
	(
		SELECT * FROM PetStore.AnimalType
		WHERE AnimalType = @AnimalType
	)
	BEGIN
		SET NOCOUNT ON

		INSERT INTO PetStore.AnimalType (AnimalType)
		VALUES(@animalType);

		SET NOCOUNT OFF
	END
END
GO

-- test the insert proc
SELECT 'Testing the INSERT proc on AnimalType'
EXEC PetStore.InsertAnimalType 'Dog';
EXEC PetStore.InsertAnimalType 'Cat';
EXEC PetStore.InsertAnimalType 'Fish';
EXEC PetStore.InsertAnimalType 'Bird';
EXEC PetStore.InsertAnimalType 'Faculty';
-- use the view to see the table
SELECT * FROM PetStore.vwAnimalType;
GO

-- animal type table select all proc
CREATE OR ALTER PROC PetStore.SelectAllAnimalTypes
AS
BEGIN
	SET NOCOUNT ON

	SELECT AnimalTypeId, AnimalType
	FROM PetStore.vwAnimalType

	SET NOCOUNT OFF
END
GO

-- animal type table select type by id
CREATE OR ALTER PROC PetStore.SelectAnimalTypeById
(
	@animalTypeId INT
)
AS
BEGIN
	SET NOCOUNT ON

	SELECT AnimalTypeId, AnimalType
	FROM PetStore.vwAnimalType
	WHERE AnimalTypeId = @animalTypeId;

	SET NOCOUNT OFF
END
GO

-- animal type table test the SELECT procs
SELECT 'Testing all SELECT on AnimalType'
EXEC PetStore.SelectAnimalTypes
SELECT 'Testing the single SELECT on AnimalType'
EXEC PetStore.SelectAnimalTypeById @animalTypeId = 1;
GO

-- animal type table update proc
CREATE OR ALTER PROC PetStore.UpdateAnimalType
(
	@animalTypeId INT
	, @animalType VARCHAR(50)
)
AS
BEGIN
	IF NOT EXISTS -- prevent repeat animal types
	(
		SELECT * FROM PetStore.AnimalType
		WHERE AnimalType = @AnimalType
	)
	BEGIN
		SET NOCOUNT ON

		UPDATE PetStore.AnimalType
		SET AnimalType = @animalType
		WHERE AnimalTypeId = @animalTypeId;

		SET NOCOUNT OFF
	END
END
GO

-- animal type table testing update proc
SELECT 'Testing UPDATE on AnimalType'
EXEC PetStore.SelectAnimalTypeById @animalTypeId = 1;
EXEC PetStore.UpdateAnimalType @animalTypeId = 1, @animalType = 'Puppy';
EXEC PetStore.UpdateAnimalType @animalTypeId = 4, @animalType = 'Puppy';
EXEC PetStore.SelectAnimalTypeById @animalTypeId = 1;
SELECT * FROM PetStore.vwAnimalType;
GO

-- animal type delete proc
CREATE OR ALTER PROC PetStore.DeleteAnimalType
(
	@animalTypeId INT
)
AS
BEGIN
	SET NOCOUNT ON

	DELETE PetStore.AnimalType
	WHERE AnimalTypeId = @animalTypeId;

	SET NOCOUNT OFF
END
GO

-- animal type table testing delete proc
SELECT 'Testing DELETE on AnimalType'
EXEC PetStore.SelectAnimalTypes;
EXEC PetStore.DeleteAnimalType @animalTypeId = 5;
EXEC PetStore.SelectAnimalTypes;
GO


ALTER TABLE PetStore.Animal DROP CONSTRAINT IF EXISTS [fkAnimal_AnimalBreed]
GO

DROP TABLE IF EXISTS PetStore.AnimalBreed;
GO

CREATE TABLE PetStore.AnimalBreed
(
	AnimalBreedId INT IDENTITY(1, 1)	NOT NULL
	, AnimalBreed VARCHAR(50)			NULL -- dachsund, labrador, calico, goldfish, finch, etc
)
;
GO

-- primary key animalbreed id
ALTER TABLE PetStore.AnimalBreed
	ADD CONSTRAINT pkAnimalBreedId PRIMARY KEY (AnimalBreedId);
GO

CREATE OR ALTER VIEW PetStore.vwAnimalBreed
AS
SELECT
	AnimalBreedId
	, AnimalBreed
FROM PetStore.AnimalBreed
GO

-- animal breed table insert proc
CREATE OR ALTER PROC PetStore.InsertAnimalBreed
(
	@animalBreed VARCHAR(50) NULL -- dachsund, labrador, calico, goldfish, finch, etc
)
AS
BEGIN
	IF NOT EXISTS -- make sure the animal breed is unique
	(
		SELECT * FROM PetStore.AnimalBreed
		WHERE AnimalBreed = @AnimalBreed
	)
	BEGIN
		SET NOCOUNT ON

		INSERT INTO PetStore.AnimalBreed (AnimalBreed)
		VALUES(@AnimalBreed);

		SET NOCOUNT OFF
	END
END
GO

-- animal breed table testing the insert proc
SELECT 'Testing the INSERT proc on AnimalBreed'
EXEC PetStore.InsertAnimalBreed @animalBreed = 'Dachsund';
EXEC PetStore.InsertAnimalBreed @animalBreed = 'Terrior';
EXEC PetStore.InsertAnimalBreed @animalBreed = 'Calico';
EXEC PetStore.InsertAnimalBreed @animalBreed = 'Goldfish';
EXEC PetStore.InsertAnimalBreed @animalBreed = 'Finch';
EXEC PetStore.InsertAnimalBreed @animalBreed = 'Faculty';
SELECT * FROM PetStore.vwAnimalBreed;
GO

-- animal breed table select all proc
CREATE OR ALTER PROC PetStore.SelectAllAnimalBreeds
AS
BEGIN
	SET NOCOUNT ON

	SELECT AnimalBreedId, AnimalBreed
	FROM PetStore.vwAnimalBreed

	SET NOCOUNT OFF
END
GO

-- animal breed table select by id proc
CREATE OR ALTER PROC PetStore.SelectAnimalBreedById
(
	@animalBreedId INT
)
AS
BEGIN
	SET NOCOUNT ON

	SELECT AnimalBreedId, AnimalBreed
	FROM PetStore.vwAnimalBreed
	WHERE AnimalBreedId = @animalBreedId;

	SET NOCOUNT OFF
END
GO

-- animal breed table testing select procs
SELECT 'Testing all SELECT on AnimalBreed'
EXEC PetStore.SelectAnimalBreeds
SELECT 'Testing the single SELECT on AnimalBreed'
EXEC PetStore.SelectAnimalBreedById @animalBreedId = 1;
GO

-- animal breed table update proc
CREATE OR ALTER PROC PetStore.UpdateAnimalBreed
(
	@animalBreedId INT
	, @animalBreed VARCHAR(50)
)
AS
BEGIN
	IF NOT EXISTS -- make sure animal breed isn't in table already
	(
		SELECT * FROM PetStore.AnimalBreed
		WHERE AnimalBreed = @AnimalBreed
	)
	BEGIN
		SET NOCOUNT ON

		UPDATE PetStore.AnimalBreed
		SET AnimalBreed = @animalBreed
		WHERE AnimalBreedId = @animalBreedId;

		SET NOCOUNT OFF
	END
END
GO

-- animal breed table testing update proc
SELECT 'Testing UPDATE on AnimalBreed'
EXEC PetStore.SelectAnimalBreedById @animalBreedId = 1;
EXEC PetStore.UpdateAnimalBreed @animalBreedId = 1, @animalBreed = 'Labrador';
EXEC PetStore.SelectAnimalBreedById @animalBreedId = 1;
GO

EXEC PetStore.SelectAnimalBreeds;
GO

-- animal breed type delete proc
CREATE OR ALTER PROC PetStore.DeleteAnimalBreed
(
	@animalBreedId INT
)
AS
BEGIN
	SET NOCOUNT ON

	DELETE PetStore.AnimalBreed
	WHERE AnimalBreedId = @animalBreedId;

	SET NOCOUNT OFF
END
GO

-- test the proc
SELECT 'Testing DELETE on AnimalBreed'
EXEC PetStore.SelectAnimalBreeds;
EXEC PetStore.DeleteAnimalBreed @animalBreedId = 6;
EXEC PetStore.SelectAnimalBreeds;
GO


DROP TABLE IF EXISTS PetStore.AnimalInfo;
GO
-- completed table
CREATE TABLE PetStore.AnimalInfo
(
	AnimalId				INT	IDENTITY(1,1)	NOT NULL -- integer value,ID for specific animal
	, AnimalFixed			BIT					NOT NULL -- whether it spayed or not or not applicable (like for birds or fish)
	, AnimalBirthDate		DATE				NULL -- day it was born, found, whatever
)
;
GO
-- primary key animalinfo id
ALTER TABLE PetStore.AnimalInfo
	ADD CONSTRAINT pkAnimalInfoId PRIMARY KEY NONCLUSTERED (AnimalId);
GO

-- foreign key animal id
ALTER TABLE PetStore.AnimalInfo
	ADD CONSTRAINT fkAnimalInfo_Animal FOREIGN KEY (AnimalId)
REFERENCES PetStore.Animal (AnimalId);
GO

-- select all animal info rows
CREATE OR ALTER PROC PetStore.GetAllAnimalInfo
AS
BEGIN
    SELECT * FROM PetStore.AnimalInfo;
END
GO

-- select an animal by id
CREATE OR ALTER PROC PetStore.GetAnimalInfoById
    @AnimalId INT
AS
BEGIN
    SELECT * FROM PetStore.AnimalInfo
	WHERE AnimalId = @AnimalId;
END
GO

-- animal info test the SELECT procs
SELECT 'Testing all SELECT on AnimalInfo'
EXEC PetStore.GetAllAnimalInfo
SELECT 'Testing the single SELECT on Animal'
EXEC PetStore.GetAnimalInfoById @animalId = 1;
GO

-- insert animal info column
CREATE OR ALTER PROC PetStore.InsertAnimalInfo
	@AnimalId INT
    , @AnimalFixed BIT
    , @AnimalBirthDate DATE
AS
BEGIN
	IF EXISTS -- animal id must exist in animal table 
	(
		SELECT * FROM PetStore.Animal
		WHERE AnimalId = @AnimalId
	)
	BEGIN
		SET NOCOUNT ON;

		SET IDENTITY_INSERT PetStore.AnimalInfo ON;
		INSERT INTO PetStore.AnimalInfo (AnimalId, AnimalFixed, AnimalBirthDate)
		VALUES (@AnimalId, @AnimalFixed, @AnimalBirthDate);
		SET IDENTITY_INSERT PetStore.AnimalInfo OFF;
	END
END
GO

SELECT 'Testing the INSERT proc on AnimalInfo'
EXEC PetStore.InsertAnimalInfo @AnimalId = 1, @AnimalFixed = 1, @AnimalBirthDate = '2022-01-01'
EXEC PetStore.InsertAnimalInfo @AnimalId = 2, @AnimalFixed = 1, @AnimalBirthDate = '2023-03-03'
EXEC PetStore.InsertAnimalInfo @AnimalId = 3, @AnimalFixed = 0, @AnimalBirthDate = '2022-12-24'
EXEC PetStore.InsertAnimalInfo @AnimalId = 4, @AnimalFixed = 0, @AnimalBirthDate = '2017-08-14'
SELECT * FROM PetStore.AnimalInfo
GO

-- update an animal info record
CREATE OR ALTER PROC PetStore.UpdateAnimalInfo
    @AnimalId INT
    , @AnimalFixed BIT
    , @AnimalBirthDate DATE
AS
BEGIN
    UPDATE PetStore.AnimalInfo
    SET AnimalFixed = @AnimalFixed, AnimalBirthDate = @AnimalBirthDate
    WHERE AnimalId = @AnimalId;
END
GO

-- animal info testing update proc
SELECT 'Testing UPDATE on AnimalInfo'
EXEC PetStore.GetAnimalInfoById @animalId = 1;
EXEC PetStore.GetAnimalInfoById @animalId = 2;
EXEC PetStore.UpdateAnimalInfo 1, 0, '2019-01-01';
EXEC PetStore.UpdateAnimalInfo 2, 1, '2023-03-02';
EXEC PetStore.GetAnimalInfoById @animalId = 1;
EXEC PetStore.GetAnimalInfoById @animalId = 2;
SELECT * FROM PetStore.AnimalInfo;
GO

-- delete animal info
CREATE OR ALTER PROC PetStore.DeleteAnimalInfo
    @AnimalId INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM PetStore.AnimalInfo
    WHERE AnimalId = @AnimalId;
END
GO

-- animal info testing delete proc
SELECT 'Testing DELETE on Animal Info'
EXEC PetStore.GetAllAnimalInfo;
EXEC PetStore.DeleteAnimalInfo @animalId = 4;
EXEC PetStore.GetAllAnimalInfo;
GO

-- reinsert right afterwards though
EXEC PetStore.InsertAnimalInfo @AnimalId = 4, @AnimalFixed = 0, @AnimalBirthDate = '2017-08-14'

SELECT * FROM PetStore.AnimalInfo;
GO


ALTER TABLE PetStore.AnimalStorage DROP CONSTRAINT IF EXISTS [fkAnimalStorage_StoreLocation]
GO

DROP TABLE IF EXISTS PetStore.StoreLocation;
GO
-- possibly break up by putting store location and max num occupants into seperate table
-- break up container type and store location
CREATE TABLE PetStore.StoreLocation
(
	StoreLocationId			INT	IDENTITY(1,1)	NOT NULL
	, StoreLocation			VARCHAR(100)		NOT NULL -- physical location in store
	, MaxNumberOfOccupants	INT					NULL -- most animals that can be kept here safely
)
;
GO
-- primary key animal storage id
ALTER TABLE PetStore.StoreLocation
	ADD CONSTRAINT pkStoreLocationId PRIMARY KEY (StoreLocationId);
GO

-- select all store locations 
CREATE OR ALTER PROC PetStore.GetAllStoreLocations
AS
BEGIN
    SELECT * FROM PetStore.StoreLocation;
END;
GO

-- select store location by id
CREATE OR ALTER PROC PetStore.GetStoreLocationById
    @StoreLocationId INT
AS
BEGIN
    SELECT * FROM PetStore.StoreLocation
	WHERE StoreLocationId = @StoreLocationId;
END;
GO

-- store location test the SELECT procs
SELECT 'Testing all SELECT on StoreLocation'
EXEC PetStore.GetAllStoreLocations
SELECT 'Testing the single SELECT on Animal'
EXEC PetStore.GetStoreLocationById @StoreLocationId = 1;
GO

-- insert store location record
CREATE OR ALTER PROC PetStore.InsertStoreLocation
    @StoreLocation VARCHAR(100)
    , @MaxNumberOfOccupants INT
AS
BEGIN
	IF NOT EXISTS -- make sure store location value is unique
	(
		SELECT * FROM PetStore.StoreLocation
		WHERE StoreLocation = @StoreLocation
	)
	BEGIN
		INSERT INTO PetStore.StoreLocation (StoreLocation, MaxNumberOfOccupants)
		VALUES (@StoreLocation, @MaxNumberOfOccupants);
	END
END;
GO

-- testing the insert proc for store location
SELECT 'Testing the INSERT proc on StoreLocation';
EXEC PetStore.InsertStoreLocation 'Front Area', 20;
EXEC PetStore.InsertStoreLocation 'Behind Counter', 12;
EXEC PetStore.InsertStoreLocation 'Left Wall', 70;
EXEC PetStore.InsertStoreLocation 'Display Tables', 8;
SELECT * FROM PetStore.StoreLocation;
GO

-- update store location record
CREATE OR ALTER PROC PetStore.UpdateStoreLocation
    @StoreLocationId INT
    , @StoreLocation VARCHAR(100)
    , @MaxNumberOfOccupants INT
AS
BEGIN
    UPDATE PetStore.StoreLocation 
    SET StoreLocation = @StoreLocation, MaxNumberOfOccupants = @MaxNumberOfOccupants
    WHERE StoreLocationId = @StoreLocationId;
END;
GO

-- store location testing update proc
SELECT 'Testing UPDATE on StoreLocation'
EXEC PetStore.GetStoreLocationById @StoreLocationId = 1;
EXEC PetStore.GetStoreLocationById @StoreLocationId = 2;
EXEC PetStore.UpdateStoreLocation 1, 'Front Quarters', 35;
EXEC PetStore.UpdateStoreLocation 2, 'Behind Counter', 14;
EXEC PetStore.GetStoreLocationById @StoreLocationId = 1;
EXEC PetStore.GetStoreLocationById @StoreLocationId = 2;
SELECT * FROM PetStore.StoreLocation;
GO

-- delete store location record
CREATE OR ALTER PROC PetStore.DeleteStoreLocation
    @StoreLocationId INT
AS
BEGIN
	-- delete animal storages within this store location
	DELETE FROM PetStore.AnimalStorage
	WHERE StoreLocationId = @StoreLocationId;

	-- delete a store location
    DELETE FROM PetStore.StoreLocation
	WHERE StoreLocationId = @StoreLocationId;
END;
GO

-- store location testing delete proc
SELECT 'Testing DELETE on Store Location'
EXEC PetStore.GetAllStoreLocations;
EXEC PetStore.DeleteStoreLocation @StoreLocationId = 4;
EXEC PetStore.GetAllStoreLocations;
GO

SELECT * FROM PetStore.StoreLocation;
GO


DROP TABLE IF EXISTS PetStore.AnimalStorage;
GO
-- possibly break up by putting store location and max num occupants into seperate table
-- break up container type and store location
CREATE TABLE PetStore.AnimalStorage
(
	AnimalId				INT	IDENTITY(1,1)	NOT NULL -- integer value,ID for specific animal
	, ContainerTypeId		INT					NOT NULL -- kennel, fish tank, other tank, box, etc.
	, StoreLocationId		INT					NULL -- physical location in store
)
;
GO
-- primary key animal storage id
ALTER TABLE PetStore.AnimalStorage
	ADD CONSTRAINT pkAnimalIdContainerTypeId PRIMARY KEY (AnimalId);
GO

-- foriegn key animal id
ALTER TABLE PetStore.AnimalStorage
	ADD CONSTRAINT fkAnimalStorage_Animal FOREIGN KEY (AnimalId)
REFERENCES PetStore.Animal (AnimalId);
GO

-- foreign key container type id
ALTER TABLE PetStore.AnimalStorage
	ADD CONSTRAINT fkAnimalStorage_ContainerType FOREIGN KEY (ContainerTypeId)
REFERENCES PetStore.ContainerType (ContainerTypeId);
GO

-- foreign key storage location id
ALTER TABLE PetStore.AnimalStorage
	ADD CONSTRAINT fkAnimalStorage_StoreLocation FOREIGN KEY (StoreLocationId)
REFERENCES PetStore.StoreLocation (StoreLocationId);
GO

-- select all animal storage records
CREATE OR ALTER PROC PetStore.GetAllAnimalStorage
AS
BEGIN
    SELECT *
    FROM PetStore.AnimalStorage
END
GO

-- select animal storage record by animal id
CREATE OR ALTER PROC PetStore.GetAnimalStorageById
    @AnimalId INT
AS
BEGIN
    SELECT *
    FROM PetStore.AnimalStorage
    WHERE AnimalId = @AnimalId
END
GO

-- animal storage test the SELECT procs
SELECT 'Testing all SELECT on AnimalStorage'
EXEC PetStore.GetAllAnimalStorage
SELECT 'Testing the single SELECT on AnimalStorage'
EXEC PetStore.GetAnimalStorageById @AnimalId = 1;
GO

-- insert animal storage record
CREATE OR ALTER PROC PetStore.InsertAnimalStorage
	@AnimalId INT
    , @ContainerTypeId INT
    , @StoreLocationId INT
AS
BEGIN
	IF EXISTS -- animal id must exist in animal table
	(
		SELECT * FROM PetStore.Animal
		WHERE AnimalId = @AnimalId
	)
	BEGIN
		IF EXISTS -- store location must exist in store location table
		(
			SELECT * FROM PetStore.StoreLocation
			WHERE StoreLocationId = @StoreLocationId
		)
		BEGIN
			IF EXISTS -- container type must exist in container type table
			(
				SELECT * FROM PetStore.ContainerType
				WHERE ContainerTypeId = @ContainerTypeId
			)
			BEGIN
				INSERT INTO PetStore.AnimalStorage (ContainerTypeId, StoreLocationId)
				VALUES (@ContainerTypeId, @StoreLocationId)
			END
		END	
	END
END
GO

SELECT 'Testing the INSERT proc on AnimalStorage';
EXEC PetStore.InsertAnimalStorage 1, 1, 1;
EXEC PetStore.InsertAnimalStorage 2, 2, 2;
EXEC PetStore.InsertAnimalStorage 2, 3, 3;
EXEC PetStore.InsertAnimalStorage 4, 4, 4;
SELECT * FROM PetStore.AnimalStorage;
GO

-- update animal storage record
CREATE OR ALTER PROC PetStore.UpdateAnimalStorage
    @AnimalId INT
    , @ContainerTypeId INT
    , @StoreLocationId INT
AS
BEGIN
    UPDATE PetStore.AnimalStorage
    SET ContainerTypeId = @ContainerTypeId, StoreLocationId = @StoreLocationId
    WHERE AnimalId = @AnimalId
END
GO

-- animal storage testing update proc
SELECT 'Testing UPDATE on StoreLocation'
EXEC PetStore.GetAnimalStorageById @AnimalId = 1;
EXEC PetStore.GetAnimalStorageById @AnimalId = 2;
EXEC PetStore.UpdateAnimalStorage 1, 2, 2;
EXEC PetStore.UpdateAnimalStorage 2, 1, 1;
EXEC PetStore.GetAnimalStorageById @AnimalId = 1;
EXEC PetStore.GetAnimalStorageById @AnimalId = 2;
SELECT * FROM PetStore.AnimalStorage;
GO

-- delete animal storage record
CREATE OR ALTER PROC PetStore.DeleteAnimalStorage
    @AnimalId INT
AS
BEGIN
    DELETE FROM PetStore.AnimalStorage
    WHERE AnimalId = @AnimalId
END
GO

-- animal storage testing delete proc
SELECT 'Testing DELETE on AnimalStorage'
EXEC PetStore.GetAllAnimalStorage;
EXEC PetStore.DeleteAnimalStorage @AnimalId = 4;
EXEC PetStore.GetAllAnimalStorage;
GO

SELECT * FROM PetStore.AnimalStorage;
GO


IF (OBJECT_ID('PetStore.FK_Container_ContainerType_ContainerTypeId', 'F') IS NOT NULL)
BEGIN
	ALTER TABLE PetStore.Container DROP CONSTRAINT
		FK_Container_ContainerType_ContainerTypeId
END

ALTER TABLE PetStore.AnimalStorage DROP CONSTRAINT IF EXISTS [fkAnimalStorage_ContainerType]
GO

DROP TABLE IF EXISTS PetStore.ContainerType;
GO

-- create container type table
CREATE TABLE PetStore.ContainerType
(
	ContainerTypeId INT IDENTITY(1, 1)	NOT NULL
	, ContainerType VARCHAR(50)			NOT NULL -- kennel, fish tank, aquarium, box, etc.
)
;
GO

-- primary key container type id
ALTER TABLE PetStore.ContainerType
	ADD CONSTRAINT pkContainerTypeId PRIMARY KEY (ContainerTypeId);
GO

-- create a view for container type table
CREATE OR ALTER VIEW PetStore.vwContainerType
AS
SELECT
	ContainerTypeId
	, ContainerType
FROM PetStore.ContainerType
GO

-- container type insert proc
CREATE OR ALTER PROC PetStore.InsertContainerType
(
	@containerType VARCHAR(50) NULL -- kennel, fish tank, dry aquarium, box, etc.
)
AS
BEGIN
	IF NOT EXISTS -- make sure no repeat container types
	(
		SELECT * FROM PetStore.ContainerType
		WHERE ContainerType = @ContainerType
	)
	BEGIN
		SET NOCOUNT ON

		INSERT INTO PetStore.ContainerType (ContainerType)
		VALUES(@containerType);

		SET NOCOUNT OFF
	END
END
GO

-- container type table testing the insert proc
SELECT 'Testing the INSERT proc on ContainerType';
EXEC PetStore.InsertContainerType @containerType = 'Kennel';
EXEC PetStore.InsertContainerType @containerType = 'Fish Tank';
EXEC PetStore.InsertContainerType @containerType = 'Dry Aquarium';
EXEC PetStore.InsertContainerType @containerType = 'Box';
EXEC PetStore.InsertContainerType @containerType = 'Dr Myers''Office';
SELECT * FROM PetStore.vwContainerType;
GO

-- container type table select all proc
CREATE OR ALTER PROC PetStore.SelectContainerTypes
AS
BEGIN
	SET NOCOUNT ON

	SELECT ContainerTypeId, ContainerType
	FROM PetStore.vwContainerType

	SET NOCOUNT OFF
END
GO

-- container type table select by id proc
CREATE OR ALTER PROC PetStore.SelectContainerTypeById
(
	@containerTypeId INT
)
AS
BEGIN
	SET NOCOUNT ON

	SELECT ContainerTypeId, ContainerType
	FROM PetStore.vwContainerType
	WHERE ContainerTypeId = @containerTypeId;

	SET NOCOUNT OFF
END
GO

-- container type table testing the SELECT procs
SELECT 'Testing all SELECT on ContainerType'
EXEC PetStore.SelectContainerTypes
SELECT 'Testing the single SELECT on ContainerType'
EXEC PetStore.SelectContainerTypeById @containerTypeId = 1;
GO

-- container type table update proc
CREATE OR ALTER PROC PetStore.UpdateContainerType
(
	@containerTypeId INT
	, @containerType VARCHAR(50)
)
AS
BEGIN
	IF NOT EXISTS -- make sure no repeating container types
	(
		SELECT * FROM PetStore.ContainerType
		WHERE ContainerType = @ContainerType
	)
	BEGIN
		SET NOCOUNT ON

		UPDATE PetStore.ContainerType
		SET ContainerType = @containerType
		WHERE ContainerTypeId = @containerTypeId;

		SET NOCOUNT OFF
	END
END
GO

-- container type table testing update proc
SELECT 'Testing UPDATE on ContainerType'
EXEC PetStore.SelectContainerTypeById @containerTypeId = 1;
EXEC PetStore.UpdateContainerType @containerTypeId = 1, @containerType = 'Large Kennel';
EXEC PetStore.SelectContainerTypeById @containerTypeId = 1;
GO

-- container type table delete proc
CREATE OR ALTER PROC PetStore.DeleteContainerType
(
	@containerTypeId INT
)
AS
BEGIN
	SET NOCOUNT ON

	DELETE PetStore.ContainerType
	WHERE ContainerTypeId = @containerTypeId;

	SET NOCOUNT OFF
END
GO

-- container type table testing the delete proc
SELECT 'Testing DELETE on ContainerType'
EXEC PetStore.SelectContainerTypes;
EXEC PetStore.DeleteContainerType @containerTypeId = 5;
EXEC PetStore.SelectContainerTypes;
GO


ALTER TABLE PetStore.CustomerContact DROP CONSTRAINT IF EXISTS [fkCustomerContact_Customer]
GO

ALTER TABLE PetStore.Purchase DROP CONSTRAINT IF EXISTS [fkPurchase_Customer]
GO

DROP TABLE IF EXISTS PetStore.Customer;
GO
-- completed table
CREATE TABLE PetStore.Customer
(
	CustomerId				INT	IDENTITY(1,1)	NOT NULL
	, CustomerName			VARCHAR(50)			NOT NULL -- person buying the pet
)
;
GO
-- primary key customer id
ALTER TABLE PetStore.Customer
	ADD CONSTRAINT pkCustomerId PRIMARY KEY (CustomerId);
GO

-- select all customers
CREATE OR ALTER PROC PetStore.GetAllCustomers
AS
BEGIN
    SELECT *
    FROM PetStore.Customer;
END
GO

-- select customers by id
CREATE OR ALTER PROC PetStore.GetCustomerById
    @CustomerId INT
AS
BEGIN
    SELECT *
    FROM PetStore.Customer
    WHERE CustomerId = @CustomerId;
END
GO

-- customer test the SELECT procs
SELECT 'Testing all SELECT on Customer'
EXEC PetStore.GetAllCustomers
SELECT 'Testing the single SELECT on Customer'
EXEC PetStore.GetCustomerById @CustomerId = 1;
GO

-- insert a customer record
CREATE OR ALTER PROC PetStore.InsertCustomer
    @CustomerName VARCHAR(50)
AS
BEGIN
	-- allowing for multiple customers to have the same name
    INSERT INTO PetStore.Customer (CustomerName)
    VALUES (@CustomerName);
END
GO

SELECT 'Testing the INSERT proc on Customer';
EXEC PetStore.InsertCustomer 'Rufus McGee';
EXEC PetStore.InsertCustomer 'Sarah McGee';
EXEC PetStore.InsertCustomer 'Amy Johnson';
EXEC PetStore.InsertCustomer 'John Smith';
SELECT * FROM PetStore.Customer;
GO

-- update a customer record
CREATE OR ALTER PROC PetStore.UpdateCustomer
    @CustomerId INT
    , @CustomerName VARCHAR(50)
AS
BEGIN
    UPDATE PetStore.Customer
    SET CustomerName = @CustomerName
    WHERE CustomerId = @CustomerId;
END
GO

-- customer testing update proc
SELECT 'Testing UPDATE on Customer'
EXEC PetStore.GetCustomerById @CustomerId = 1;
EXEC PetStore.GetCustomerById @CustomerId = 2;
EXEC PetStore.UpdateCustomer 1, 'Rufus Madison';
EXEC PetStore.UpdateCustomer 2, 'Sarah Madison';
EXEC PetStore.GetCustomerById @CustomerId = 1;
EXEC PetStore.GetCustomerById @CustomerId = 2;
SELECT * FROM PetStore.Customer;
GO

-- delete a customer
CREATE OR ALTER PROC PetStore.DeleteCustomer
    @CustomerId INT
AS
BEGIN
    DELETE FROM PetStore.Customer
    WHERE CustomerId = @CustomerId;
END
GO

-- customer testing delete proc
SELECT 'Testing DELETE on Customer'
EXEC PetStore.GetAllCustomers;
EXEC PetStore.DeleteCustomer @CustomerId = 4;
EXEC PetStore.GetAllCustomers;
GO

SELECT * FROM PetStore.Customer;
GO


DROP TABLE IF EXISTS PetStore.CustomerContact;
GO
-- completed table
CREATE TABLE PetStore.CustomerContact
(
	CustomerId				INT	IDENTITY(1,1)	NOT NULL
	, CustomerPhone			VARCHAR(50)			NOT NULL -- person buying the pet
	, CustomerEmail			VARCHAR(50)			NOT NULL -- person phone #
	, CustomerAddress		VARCHAR(200)		NULL -- person address
)
;
GO
-- primary key customer id
ALTER TABLE PetStore.CustomerContact
	ADD CONSTRAINT pkCustomerContactId PRIMARY KEY (CustomerId);
GO

-- foriegn key customer id
ALTER TABLE PetStore.CustomerContact
	ADD CONSTRAINT fkCustomerContact_Customer FOREIGN KEY (CustomerId)
REFERENCES PetStore.Customer (CustomerId);
GO

-- select all customer contacts
CREATE OR ALTER PROC PetStore.GetAllCustomerContacts
AS
BEGIN
	SELECT *
	FROM PetStore.CustomerContact;
END
GO

-- select customer contact by id
CREATE OR ALTER PROC PetStore.GetCustomerContactById
	@CustomerId INT
AS
BEGIN
	SELECT *
	FROM PetStore.CustomerContact
	WHERE CustomerId = @CustomerId;
END
GO

-- customer contact test the SELECT procs
SELECT 'Testing all SELECT on CustomerContact'
EXEC PetStore.GetAllCustomerContacts
SELECT 'Testing the single SELECT on CustomerContact'
EXEC PetStore.GetCustomerContactById @CustomerId = 1;
GO

-- insert customer record
CREATE OR ALTER PROC PetStore.InsertCustomerContact
	@CustomerId	INT
	, @CustomerPhone VARCHAR(50)
	, @CustomerEmail VARCHAR(50)
	, @CustomerAddress VARCHAR(200)
AS
BEGIN
	IF EXISTS -- customer must exist to have contact info
	(
		SELECT * FROM PetStore.Customer
		WHERE CustomerId = @CustomerId
	)
	BEGIN
		IF NOT EXISTS -- most stores only allow a phone number to be used once
		(
			SELECT * FROM PetStore.CustomerContact
			WHERE CustomerPhone = @CustomerPhone
		)
		BEGIN
			INSERT INTO PetStore.CustomerContact (CustomerPhone, CustomerEmail, CustomerAddress)
			VALUES (@CustomerPhone, @CustomerEmail, @CustomerAddress);
		END
	END
END
GO

SELECT 'Testing the INSERT proc on CustomerContact';
EXEC PetStore.InsertCustomerContact 1, '911-911-9111', 'RufusMcGee@nnu.edu', '1234 NW Orchard Street, Nampa, ID';
EXEC PetStore.InsertCustomerContact 2, '123-456-7890', 'SarahMcGee@nnu.edu', '1234 NW Orchard Street, Nampa, ID';
EXEC PetStore.InsertCustomerContact 3, '555-444-3333', 'ajohnson@nnu.edu', '623 S University Blvd, Nampa, ID';
EXEC PetStore.InsertCustomerContact 4, '222-111-0000', 'johnsmith@yahoo.com', '821 W Misty Lane, Redmond, WA';
SELECT * FROM PetStore.CustomerContact;
GO

-- update customer record
CREATE OR ALTER PROC PetStore.UpdateCustomerContact
	@CustomerId INT
	, @CustomerPhone VARCHAR(50)
	, @CustomerEmail VARCHAR(50)
	, @CustomerAddress VARCHAR(200)
AS
BEGIN
	UPDATE PetStore.CustomerContact
	SET CustomerPhone = @CustomerPhone, CustomerEmail = @CustomerEmail, CustomerAddress = @CustomerAddress
	WHERE CustomerId = @CustomerId;
END
GO

-- customer contact testing update proc
SELECT 'Testing UPDATE on CustomerContact'
EXEC PetStore.GetCustomerContactById @CustomerId = 1;
EXEC PetStore.GetCustomerContactById @CustomerId = 2;
EXEC PetStore.UpdateCustomerContact 1, '000-000-9110', 'RufusMadison@nnu.edu', '12345 NW Orchard Street, Nampa, ID';
EXEC PetStore.UpdateCustomerContact 2, '123-456-7890', 'SarahMadison@nnu.edu', '12345 NW Orchard Street, Nampa, ID';
EXEC PetStore.GetCustomerContactById @CustomerId = 1;
EXEC PetStore.GetCustomerContactById @CustomerId = 2;
SELECT * FROM PetStore.CustomerContact;
GO

-- delete customer record
CREATE OR ALTER PROC PetStore.DeleteCustomerContact
	@CustomerId INT
AS
BEGIN
	DELETE FROM PetStore.CustomerContact
	WHERE CustomerId = @CustomerId;
END
GO

-- customer contact testing delete proc
SELECT 'Testing DELETE on CustomerContact'
EXEC PetStore.GetAllCustomerContacts;
EXEC PetStore.DeleteCustomerContact @CustomerId = 3;
EXEC PetStore.GetAllCustomerContacts;
GO

SELECT * FROM PetStore.CustomerContact;
GO


DROP TABLE IF EXISTS PetStore.Purchase;
GO
-- completed table
CREATE TABLE PetStore.Purchase
(
	PurchaseId				INT	IDENTITY(1,1)	NOT NULL
	, CustomerId			INT					NOT NULL
	, PurchaseDate			DATE				NULL -- date of customer purchase
	-- could have total price as a calculated column 
)
;
GO
-- primary key purchase id	
ALTER TABLE PetStore.Purchase
	ADD CONSTRAINT pkPurchaseId PRIMARY KEY NONCLUSTERED (PurchaseId);
GO

-- foreign key purchase id	
ALTER TABLE PetStore.Purchase
	ADD CONSTRAINT fkPurchase_Customer FOREIGN KEY (CustomerId)
REFERENCES PetStore.Customer (CustomerId);
GO

-- select all purchases
CREATE OR ALTER PROC PetStore.GetAllPurchases
AS
BEGIN
    SELECT *
    FROM PetStore.Purchase;
END;
GO

-- select purchase by id
CREATE OR ALTER PROC PetStore.GetPurchaseById
    @PurchaseId INT
AS
BEGIN
    SELECT *
    FROM PetStore.Purchase
    WHERE PurchaseId = @PurchaseId;
END;
GO

-- customer contact test the SELECT procs
SELECT 'Testing all SELECT on Purchase'
EXEC PetStore.GetAllPurchases
SELECT 'Testing the single SELECT on CustomerContact'
EXEC PetStore.GetPurchaseById @PurchaseId = 1;
GO

-- insert purchase record
CREATE OR ALTER PROC PetStore.InsertPurchase
    @CustomerId INT
    , @PurchaseDate DATE
AS
BEGIN
	IF EXISTS -- make sure the customers exists in customer table
	(
		SELECT * FROM PetStore.Customer
		WHERE CustomerId = @CustomerId
	)
    INSERT INTO PetStore.Purchase (CustomerId, PurchaseDate)
    VALUES (@CustomerId, @PurchaseDate);
END;
GO

SELECT 'Testing the INSERT proc on Purchase';
EXEC PetStore.InsertPurchase 1, '12-23-2022';
EXEC PetStore.InsertPurchase 2, '1-8-2023';
EXEC PetStore.InsertPurchase 3, '4-16-2023';
EXEC PetStore.InsertPurchase 4, '3-1-2023';
SELECT * FROM PetStore.Purchase;
GO

-- update purchase record
CREATE OR ALTER PROC PetStore.UpdatePurchase
    @PurchaseId INT
    , @CustomerId INT
    , @PurchaseDate DATE
AS
BEGIN
    UPDATE PetStore.Purchase
    SET CustomerId = @CustomerId, PurchaseDate = @PurchaseDate
    WHERE PurchaseId = @PurchaseId;
END;
GO

-- purchase testing update proc
SELECT 'Testing UPDATE on Purchase'
EXEC PetStore.GetPurchaseById @PurchaseId = 1;
EXEC PetStore.GetPurchaseById @PurchaseId = 2;
EXEC PetStore.UpdatePurchase 1, 3, '09-12-2022';
EXEC PetStore.UpdatePurchase 2, 1, '2-18-2023';
EXEC PetStore.GetPurchaseById @PurchaseId = 1;
EXEC PetStore.GetPurchaseById @PurchaseId = 2;
SELECT * FROM PetStore.Purchase;
GO
 
-- delete purchase
CREATE OR ALTER PROC PetStore.DeletePurchase
    @PurchaseId INT
AS
BEGIN
    DELETE FROM PetStore.Purchase
    WHERE PurchaseId = @PurchaseId;
END;
GO

-- purchase testing delete proc
SELECT 'Testing DELETE on Purchase'
EXEC PetStore.GetAllPurchases;
EXEC PetStore.DeletePurchase @PurchaseId = 3;
EXEC PetStore.GetAllPurchases;
GO

SELECT * FROM PetStore.Purchase;
GO


DROP TABLE IF EXISTS PetStore.PurchasedAnimals;
GO
-- one purchase id to many animal id's
-- completed table
CREATE TABLE PetStore.PurchasedAnimals
(
	PurchaseId				INT	IDENTITY(1,1)	NOT NULL
	, AnimalId				INT					NOT NULL
	, Quantity				INT					NULL -- how many purchased of this animal	
)
;
GO
-- primary key purchase id
ALTER TABLE PetStore.PurchasedAnimals
	ADD CONSTRAINT pkPurchasedAnimalsId PRIMARY KEY (PurchaseId);
GO

-- foreign key animal id
ALTER TABLE PetStore.PurchasedAnimals
	ADD CONSTRAINT fkPurchasedAnimals_Animal FOREIGN KEY (AnimalId)
REFERENCES PetStore.Animal (AnimalId);
GO

-- select all purchased animals
CREATE OR ALTER PROC PetStore.GetAllPurchasedAnimals
AS
BEGIN
	SELECT *
	FROM PetStore.PurchasedAnimals
END
GO

-- select purchased animal by id
CREATE OR ALTER PROC PetStore.GetPurchasedAnimalById
	@PurchaseId INT
AS
BEGIN
	SELECT *
	FROM PetStore.PurchasedAnimals
	WHERE PurchaseId = @PurchaseId
END
GO

-- customer contact test the SELECT procs
SELECT 'Testing all SELECT on PurchasedAnimals'
EXEC PetStore.GetAllPurchasedAnimals
SELECT 'Testing the single SELECT on PurchasedAnimals'
EXEC PetStore.GetPurchasedAnimalById @PurchaseId = 1;
GO

-- insert purchased animal
CREATE OR ALTER PROC PetStore.InsertPurchasedAnimal
	@PurchaseId	INT
	, @AnimalId INT
	, @Quantity INT
AS
BEGIN
	IF EXISTS -- the purchase id must exist in purchase table
	(
		SELECT * FROM PetStore.Purchase
		WHERE PurchaseId = @PurchaseId
	)
	BEGIN
		IF EXISTS -- the animal id must exist in animal table
		(
			SELECT * FROM PetStore.Animal
			WHERE AnimalId = @AnimalId
		)
		BEGIN
			INSERT INTO PetStore.PurchasedAnimals (AnimalId, Quantity)
			VALUES (@AnimalId, @Quantity)
		END
	END
END
GO

SELECT 'Testing the INSERT proc on PurchasedAnimals';
EXEC PetStore.InsertPurchasedAnimal 1, 1, 1;
EXEC PetStore.InsertPurchasedAnimal 2, 2, 1;
EXEC PetStore.InsertPurchasedAnimal 3, 3, 1;
EXEC PetStore.InsertPurchasedAnimal 4, 4, 1;
SELECT * FROM PetStore.PurchasedAnimals;
GO

-- update purchased animal
CREATE OR ALTER PROC PetStore.UpdatePurchasedAnimal
	@PurchaseId INT
	, @AnimalId INT
	, @Quantity INT
AS
BEGIN
	UPDATE PetStore.PurchasedAnimals
	SET AnimalId = @AnimalId, Quantity = @Quantity
	WHERE PurchaseId = @PurchaseId
END
GO

-- purchase animals testing update proc
SELECT 'Testing UPDATE on PurchasedAnimals'
EXEC PetStore.GetPurchasedAnimalById @PurchaseId = 1;
EXEC PetStore.GetPurchasedAnimalById @PurchaseId = 2;
EXEC PetStore.UpdatePurchasedAnimal 1, 3, 3;
EXEC PetStore.UpdatePurchasedAnimal 2, 1, 1;
EXEC PetStore.GetPurchasedAnimalById @PurchaseId = 1;
EXEC PetStore.GetPurchasedAnimalById @PurchaseId = 2;
SELECT * FROM PetStore.PurchasedAnimals;
GO

-- delete purchased animal
CREATE OR ALTER PROC PetStore.DeletePurchasedAnimal
	@PurchaseId INT
AS
BEGIN
	DELETE FROM PetStore.PurchasedAnimals
	WHERE PurchaseId = @PurchaseId
END
GO

-- purchased animal testing delete proc
SELECT 'Testing DELETE on PurchasedAnimal'
EXEC PetStore.GetAllPurchasedAnimals;
EXEC PetStore.DeletePurchasedAnimal @PurchaseId = 3;
EXEC PetStore.GetAllPurchases;
GO

DROP TABLE IF EXISTS PetStore.AnimalPricing;
GO
-- one purchase id to many animal id's
-- completed table
CREATE TABLE PetStore.AnimalPricing
(
	AnimalId				INT					NOT NULL
	, ListPrice				DECIMAL(10, 4)		NOT NULL -- list price of each animal of this type
	, Discount				DECIMAL(4, 2)		NOT NULL -- % discount	
)
;
GO

-- primary key animal id
ALTER TABLE PetStore.AnimalPricing
	ADD CONSTRAINT pkAnimalPricingId PRIMARY KEY NONCLUSTERED (AnimalId);
GO

-- foreign key purchase id
ALTER TABLE PetStore.AnimalPricing
	ADD CONSTRAINT fkAnimalPricing_Animal FOREIGN KEY (AnimalId)
REFERENCES PetStore.Animal (AnimalId);
GO

-- select all animal pricing records
CREATE OR ALTER PROC PetStore.GetAllAnimalPricing
AS
BEGIN
	SELECT AnimalId, ListPrice, Discount
	FROM PetStore.AnimalPricing
END;
GO

-- select animal pricing by animal id
CREATE OR ALTER PROC PetStore.GetAnimalPricingById
	@AnimalId INT
AS
BEGIN
	SELECT AnimalId, ListPrice, Discount
	FROM PetStore.AnimalPricing
	WHERE AnimalId = @AnimalId
END;
GO

-- animal pricing test the SELECT procs
SELECT 'Testing all SELECT on AnimalPricing'
EXEC PetStore.GetAllAnimalPricing
SELECT 'Testing the single SELECT on AnimalPricing'
EXEC PetStore.GetAnimalPricingById @AnimalId = 1;
GO

-- insert pricing of animal
CREATE OR ALTER PROC PetStore.InsertAnimalPricing
	@AnimalId INT
	, @ListPrice DECIMAL(10,4)
	, @Discount DECIMAL(4,2)
AS
BEGIN
	IF EXISTS -- animal id must exist in animal table
	(
		SELECT * FROM PetStore.Animal
		WHERE AnimalId = @AnimalId
	)
	BEGIN
		INSERT INTO PetStore.AnimalPricing (AnimalId, ListPrice, Discount)
		VALUES (@AnimalId, @ListPrice, @Discount)
	END
END;
GO

-- testing insert proc for animal pricing table
SELECT 'Testing the INSERT proc on AnimalPricing';
EXEC PetStore.InsertAnimalPricing 1, 182.22, 0.10;
EXEC PetStore.InsertAnimalPricing 2, 123.99, 0.10;
EXEC PetStore.InsertAnimalPricing 3, 19.99, 0.10;
EXEC PetStore.InsertAnimalPricing 4, 74.99, 0.10;
SELECT * FROM PetStore.AnimalPricing;
GO

-- update pricing of animal record
CREATE OR ALTER PROC PetStore.UpdateAnimalPricing
	@AnimalId INT
	, @ListPrice DECIMAL(10,4)
	, @Discount DECIMAL(4,2)
AS
BEGIN
	UPDATE PetStore.AnimalPricing
	SET ListPrice = @ListPrice, Discount = @Discount
	WHERE AnimalId = @AnimalId
END;
GO

-- animal pricing animals testing update proc
SELECT 'Testing UPDATE on AnimalPricing'
EXEC PetStore.GetAnimalPricingById @AnimalId = 1;
EXEC PetStore.GetAnimalPricingById @AnimalId = 2;
EXEC PetStore.UpdateAnimalPricing 1, 194.22, 0.10;
EXEC PetStore.UpdateAnimalPricing 2, 143.99, 0.10;
EXEC PetStore.GetAnimalPricingById @AnimalId = 1;
EXEC PetStore.GetAnimalPricingById @AnimalId = 2;
SELECT * FROM PetStore.AnimalPricing;
GO

-- delete animal record
CREATE OR ALTER PROC PetStore.DeleteAnimalPricing
	@AnimalId INT
AS
BEGIN
	DELETE FROM PetStore.AnimalPricing
	WHERE AnimalId = @AnimalId
END;
GO

-- animal pricing testing delete proc
SELECT 'Testing DELETE on AnimalPricing'
EXEC PetStore.GetAllAnimalPricing;
EXEC PetStore.DeleteAnimalPricing @AnimalId = 3;
EXEC PetStore.GetAllAnimalPricing;
GO





-- view of purchase details
CREATE OR ALTER VIEW PetStore.PurchaseDetail AS
SELECT p.PurchaseId, p.CustomerId, c.CustomerName, p.PurchaseDate, a.AnimalId, a.AnimalName, a.AnimalGender, ap.ListPrice, ap.Discount, pa.Quantity, 
       (ap.ListPrice - (ap.ListPrice * (ap.Discount))) AS SalePrice, 
       (pa.Quantity * (ap.ListPrice - (ap.ListPrice * (ap.Discount)))) AS TotalPrice
FROM PetStore.Purchase p
INNER JOIN PetStore.Customer c ON p.CustomerId = c.CustomerId
INNER JOIN PetStore.PurchasedAnimals pa ON p.PurchaseId = pa.PurchaseId
INNER JOIN PetStore.Animal a ON pa.AnimalId = a.AnimalId
INNER JOIN PetStore.AnimalPricing ap ON a.AnimalId = ap.AnimalId
GO

-- view of animals currently in the store
CREATE OR ALTER VIEW PetStore.AnimalInventory AS
SELECT a.AnimalId, a.AnimalName, at.AnimalType, ab.AnimalBreed, a.AnimalGender, ai.AnimalFixed, ai.AnimalBirthDate
FROM PetStore.Animal a
JOIN PetStore.AnimalType at ON a.AnimalTypeId = at.AnimalTypeId
JOIN PetStore.AnimalBreed ab ON a.AnimalBreedId = ab.AnimalBreedId
JOIN PetStore.AnimalInfo ai ON a.AnimalId = ai.AnimalId;
GO

-- report of sales showing purchases by each month based on animal type
CREATE OR ALTER VIEW PetStore.PurchasesByMonthAndAnimalType AS
SELECT
    YEAR(PurchaseDate) AS PurchaseYear,
    MONTH(PurchaseDate) AS PurchaseMonth,
    AnimalType.AnimalType,
    COUNT(*) AS TotalPurchases
FROM
    PetStore.Purchase
	JOIN PetStore.PurchasedAnimals ON PetStore.PurchasedAnimals.PurchaseId = PetStore.Purchase.PurchaseId
    JOIN PetStore.Animal ON PetStore.PurchasedAnimals.AnimalId = PetStore.Animal.AnimalId
    JOIN PetStore.AnimalType ON PetStore.Animal.AnimalTypeId = PetStore.AnimalType.AnimalTypeId
GROUP BY
    YEAR(PurchaseDate),
    MONTH(PurchaseDate),
    AnimalType.AnimalType;
GO

SELECT * FROM PetStore.Purchase;
GO

-- view showing total revenue per animal type (couldn't quite figure this one out)
--CREATE OR ALTER VIEW PetStore.TotalRevenueByAnimalType
--AS
--SELECT
--    AT.AnimalType,
--    SUM(AP.ListPrice * (1 - AP.Discount/100) * COUNT(P.AnimalId)) AS TotalRevenue
--FROM PetStore.PurchasedAnimals AS P
--INNER JOIN PetStore.Animal AS A ON P.AnimalId = A.AnimalId
--INNER JOIN PetStore.AnimalType AS AT ON A.AnimalTypeId = AT.AnimalTypeId
--INNER JOIN PetStore.AnimalPricing AS AP ON A.AnimalId = AP.AnimalId
--GROUP BY AT.AnimalType;
--GO

