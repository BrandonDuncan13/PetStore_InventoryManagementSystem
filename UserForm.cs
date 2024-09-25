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
    public partial class UserForm : Form
    {
        // create a connection to the database
        SqlConnection connection = new SqlConnection(@"Data Source=.;Initial Catalog=bduncan;User ID=sa;Password=***********");
        SqlCommand command = new SqlCommand();
        SqlDataReader dataReader;

        public UserForm()
        {
            InitializeComponent();
            LoadUsers();
        }

        public void LoadUsers()
        {
            int i = 0;
            // clear rows currently in the datagridview
            dgvUser.Rows.Clear();
            // select all users from the table
            command = new SqlCommand("SELECT * FROM [User]", connection);
            // open connection to database
            connection.Open();
            // open data reader
            dataReader = command.ExecuteReader();

            while(dataReader.Read())
            {
                i++;
                dgvUser.Rows.Add(i, dataReader[0].ToString(), dataReader[1].ToString(), dataReader[2].ToString(), dataReader[3].ToString());
            }

            // close data reader and connection
            dataReader.Close();
            connection.Close();
        }

        private void btnAdd_Click(object sender, EventArgs e)
        {
            UserModuleForm userModule = new UserModuleForm();
            userModule.btnSave.Enabled = true;
            // can't update since creating user
            userModule.btnUpdate.Enabled = false;
            userModule.ShowDialog();
            // reload the users
            LoadUsers();
        }

        private void dgvUser_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {
            string colName = dgvUser.Columns[e.ColumnIndex].Name;

            if (colName == "Edit")
            {
                // create user module form
                UserModuleForm userModule = new UserModuleForm();
                // get the current values of the selected row
                userModule.txtUserName.Text = dgvUser.Rows[e.RowIndex].Cells[1].Value.ToString();
                userModule.txtFullName.Text = dgvUser.Rows[e.RowIndex].Cells[2].Value.ToString();
                userModule.txtPass.Text = dgvUser.Rows[e.RowIndex].Cells[3].Value.ToString();
                userModule.txtPhone.Text = dgvUser.Rows[e.RowIndex].Cells[4].Value.ToString();

                // display edit settings
                userModule.btnSave.Enabled = false;
                userModule.btnUpdate.Enabled = true;
                userModule.txtUserName.Enabled = false;
                userModule.ShowDialog();
            }
            else if (colName == "Delete")
            {
                if (MessageBox.Show("Are you sure you want to delete this user?", "Delete Record", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    // open connection
                    connection.Open();
                    command = new SqlCommand("DELETE FROM [User] WHERE username LIKE '" + dgvUser.Rows[e.RowIndex].Cells[1].Value.ToString() + "'", connection);
                    // execute SQL command
                    command.ExecuteNonQuery();
                    // close connection
                    connection.Close();

                    MessageBox.Show("Record has been successfully deleted!");
                }
            }
            // reload the users
            LoadUsers();
        }
    }
}
