using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace AdriansPetStore_InventoryManagementSystem
{
    public partial class ProductTypeForm : Form
    {
        // create a connection to the database
        // SqlConnection connection = new SqlConnection(@"Data Source=.;Initial Catalog=bduncan;User ID=sa;Password=1234");
        SqlConnection connection = new SqlConnection(@"Data Source=(LocalDB)\MSSQLLocalDB;AttachDbFilename=""C:\Users\Brandon Duncan\OneDrive\Documents\dbPetStoreIMS.mdf"";Integrated Security=True;Connect Timeout=30");
        SqlCommand command = new SqlCommand();
        SqlDataReader dataReader;

        public ProductTypeForm()
        {
            InitializeComponent();
            LoadCategories();
        }

        public void LoadCategories()
        {
            int i = 0;
            // clear rows currently in the datagridview
            dgvCategory.Rows.Clear();
            // select all users from the table
            command = new SqlCommand("SELECT * FROM [Category]", connection);
            // open connection to database
            connection.Open();
            // open data reader
            dataReader = command.ExecuteReader();

            while (dataReader.Read())
            {
                i++;
                dgvCategory.Rows.Add(i, dataReader[0].ToString(), dataReader[1].ToString());
            }

            // close data reader and connection
            dataReader.Close();
            connection.Close();
        }

        private void btnCatAdd_Click(object sender, EventArgs e)
        {
            ProductTypeModuleForm categoryModule = new ProductTypeModuleForm();
            categoryModule.btnSave.Enabled = true;
            // can't update since creating user
            categoryModule.btnUpdate.Enabled = false;
            categoryModule.ShowDialog();
            // reload the users
            LoadCategories();
        }

        private void dgvCategory_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {
            string colName = dgvCategory.Columns[e.ColumnIndex].Name;

            if (colName == "Edit")
            {
                // create customer module form
                ProductTypeModuleForm categoryModule = new ProductTypeModuleForm();
                // get the current values of the selected row
                categoryModule.lblCategoryId.Text = dgvCategory.Rows[e.RowIndex].Cells[1].Value.ToString();
                categoryModule.txtCategoryName.Text = dgvCategory.Rows[e.RowIndex].Cells[2].Value.ToString();

                // display edit settings
                categoryModule.btnSave.Enabled = false;
                categoryModule.btnUpdate.Enabled = true;
                categoryModule.ShowDialog();
            }
            else if (colName == "Delete")
            {
                if (MessageBox.Show("Are you sure you want to delete this category?", "Delete Record", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    // open connection
                    connection.Open();
                    command = new SqlCommand("DELETE FROM [Category] WHERE categoryid LIKE '" + dgvCategory.Rows[e.RowIndex].Cells[1].Value.ToString() + "'", connection);
                    // execute SQL command
                    command.ExecuteNonQuery();
                    // close connection
                    connection.Close();

                    MessageBox.Show("Record has been successfully deleted!");
                }
            }
            // reload the users
            LoadCategories();
        }
    }
}
