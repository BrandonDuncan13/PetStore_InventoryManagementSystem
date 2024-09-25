using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Data.SqlClient;

namespace AdriansPetStore_InventoryManagementSystem
{
    public partial class CustomerModuleForm : Form
    {
        // create a connection to the database
        SqlConnection connection = new SqlConnection(@"Data Source=(LocalDB)\MSSQLLocalDB;AttachDbFilename=""C:\Users\Brandon Duncan\OneDrive\Documents\dbPetStoreIMS.mdf"";Integrated Security=True;Connect Timeout=30");
        SqlCommand command = new SqlCommand();

        public CustomerModuleForm()
        {
            InitializeComponent();
        }

        private void picBoxClose_Click(object sender, EventArgs e)
        {
            this.Dispose();
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            try
            {
                if (MessageBox.Show("Are you sure you want to save this customer?", "Saving Record", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    command = new SqlCommand("INSERT INTO [Customer](name,phone)Values(@name, @phone)", connection);
                    command.Parameters.AddWithValue("@name", txtName.Text);
                    command.Parameters.AddWithValue("@phone", txtPhone.Text);
                    // open connection to database
                    connection.Open();
                    // execute the insert
                    command.ExecuteNonQuery();
                    // close connection
                    connection.Close();
                    MessageBox.Show("Customer has been successfully saved.");
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
                if (MessageBox.Show("Are you sure you want to update this customer?", "Update Record", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    command = new SqlCommand("UPDATE [Customer] SET name=@name,phone=@phone WHERE customerid LIKE '" + lblCId.Text + "'", connection);
                    command.Parameters.AddWithValue("@name", txtName.Text);
                    command.Parameters.AddWithValue("@phone", txtPhone.Text);
                    // open connection to database
                    connection.Open();
                    // execute the insert
                    command.ExecuteNonQuery();
                    // close connection
                    connection.Close();
                    MessageBox.Show("Customer has been successfully updated.");
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

        private void Clear() // clear the textboxes
        {
            txtName.Text = "";
            txtPhone.Text = "";

        }
    }
}
