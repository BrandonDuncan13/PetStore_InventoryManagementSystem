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
    public partial class AnimalModuleForm : Form
    {
        // create a connection to the database
        SqlConnection connection = new SqlConnection(@"Data Source=.;Initial Catalog=bduncan;User ID=sa;Password=***********");
        SqlCommand command = new SqlCommand();
        SqlDataReader dataReader;

        public AnimalModuleForm()
        {
            InitializeComponent();
            LoadCategories();
        }

        public void LoadCategories()
        {
            // clear the previous items in the combobox
            comboBoxCategory.Items.Clear();
            // select all categories
            command = new SqlCommand("SELECT categoryname FROM [Category]", connection);
            // open connection
            connection.Open();
            // open data reader
            dataReader = command.ExecuteReader();

            while (dataReader.Read())
            {
                comboBoxCategory.Items.Add(dataReader[0].ToString());
            }

            // close data reader and connection
            dataReader.Close();
            connection.Close();
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            try
            {
                if (MessageBox.Show("Are you sure you want to save this product?", "Saving Record", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    command = new SqlCommand("INSERT INTO [Product](name,qty,price,description,category)Values(@name,@qty,@price,@description,@category)", connection);
                    command.Parameters.AddWithValue("@name", txtProductName.Text);
                    command.Parameters.AddWithValue("@qty", Convert.ToInt16(txtQty.Text));
                    command.Parameters.AddWithValue("@price", Convert.ToInt16(txtPrice.Text));
                    command.Parameters.AddWithValue("@description", txtDesc.Text);
                    command.Parameters.AddWithValue("@category", comboBoxCategory.Text);
                    // open connection to database
                    connection.Open();
                    // execute the insert
                    command.ExecuteNonQuery();
                    // close connection
                    connection.Close();
                    MessageBox.Show("Product has been successfully saved.");
                }
                Clear();
                // close the form
                this.Dispose();
            }
            catch (Exception ex)
            {

                MessageBox.Show(ex.Message);
            }
        }

        private void btnUpdate_Click(object sender, EventArgs e)
        {
            try
            {
                if (MessageBox.Show("Are you sure you want to update this product?", "Update Record", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    command = new SqlCommand("UPDATE [Product] SET name=@name, qty=@qty, price=@price, description=@description, category=@category " +
                        "WHERE productid LIKE '" + lblProductId.Text + "'", connection);
                    command.Parameters.AddWithValue("@name", txtProductName.Text);
                    command.Parameters.AddWithValue("@qty", Convert.ToInt16(txtQty.Text));
                    command.Parameters.AddWithValue("@price", Convert.ToInt16(txtPrice.Text));
                    command.Parameters.AddWithValue("@description", txtDesc.Text);
                    command.Parameters.AddWithValue("@category", comboBoxCategory.Text);
                    // open connection to database
                    connection.Open();
                    // execute the insert
                    command.ExecuteNonQuery();
                    // close connection
                    connection.Close();
                    MessageBox.Show("Product has been successfully updated.");
                    this.Dispose();
                }
            }
            catch (Exception ex)
            {

                MessageBox.Show(ex.Message);
            }
        }

        private void btnClear_Click(object sender, EventArgs e)
        {
            Clear();
            btnSave.Enabled = true;
            btnUpdate.Enabled = false;
        }

        private void picBoxClose_Click(object sender, EventArgs e)
        {
            this.Dispose();
        }

        private void Clear() // clear the textboxes
        {
            txtProductName.Text = "";
            txtQty.Text = "";
            txtPrice.Text = "";
            txtDesc.Text = "";
            comboBoxCategory.Text = "";
        }
    }
}
