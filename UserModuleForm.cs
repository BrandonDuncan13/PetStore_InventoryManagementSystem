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
    public partial class UserModuleForm : Form
    {
        // create a connection to the database
        // SqlConnection connection = new SqlConnection(@"Data Source=.;Initial Catalog=bduncan;User ID=sa;Password=1234");
        SqlConnection connection = new SqlConnection(@"Data Source=(LocalDB)\MSSQLLocalDB;AttachDbFilename=""C:\Users\Brandon Duncan\OneDrive\Documents\dbPetStoreIMS.mdf"";Integrated Security=True;Connect Timeout=30");
        SqlCommand command = new SqlCommand();

        public UserModuleForm()
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
                if (txtPass.Text != txtPassRetype.Text) // check if passwords match
                {
                    MessageBox.Show("Passwords did not Match!", "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                if (MessageBox.Show("Are you sure you want to save this user?", "Saving Record", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    command = new SqlCommand("INSERT INTO [User](username,fullname,password,phone)Values(@username,@fullname,@password,@phone)", connection);
                    command.Parameters.AddWithValue("@username", txtUserName.Text);
                    command.Parameters.AddWithValue("@fullname", txtFullName.Text);
                    command.Parameters.AddWithValue("@password", txtPass.Text);
                    command.Parameters.AddWithValue("@phone", txtPhone.Text);
                    // open connection to database
                    connection.Open();
                    // execute the insert
                    command.ExecuteNonQuery();
                    // close connection
                    connection.Close();
                    MessageBox.Show("User has been successfully saved.");
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
                if (txtPass.Text != txtPassRetype.Text) // check if passwords match
                {
                    MessageBox.Show("Passwords did not Match!", "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                if (MessageBox.Show("Are you sure you want to update this user?", "Update Record", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    command = new SqlCommand("UPDATE [User] SET fullname=@fullname, password=@password, phone=@phone WHERE username LIKE '" + txtUserName.Text + "'", connection);
                    command.Parameters.AddWithValue("@fullname", txtFullName.Text);
                    command.Parameters.AddWithValue("@password", txtPass.Text);
                    command.Parameters.AddWithValue("@phone", txtPhone.Text);
                    // open connection to database
                    connection.Open();
                    // execute the insert
                    command.ExecuteNonQuery();
                    // close connection
                    connection.Close();
                    MessageBox.Show("User has been successfully updated.");
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
            txtUserName.Text = "";
            txtFullName.Text = "";
            txtPass.Text = "";
            txtPassRetype.Text = "";
            txtPhone.Text = "";
        }
    }
}
