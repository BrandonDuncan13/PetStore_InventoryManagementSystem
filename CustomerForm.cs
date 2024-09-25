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
    public partial class CustomerForm : Form
    {
        // create a connection to the database
        SqlConnection connection = new SqlConnection(@"Data Source=.;Initial Catalog=bduncan;User ID=sa;Password=***********");
        SqlCommand command = new SqlCommand();
        SqlDataReader dataReader;

        public CustomerForm()
        {
            InitializeComponent();
            LoadCustomers();
        }

        public void LoadCustomers()
        {
            int i = 0;
            // clear rows currently in the datagridview
            dgvCustomer.Rows.Clear();
            // select all users from the table
            command = new SqlCommand("SELECT * FROM [Customer]", connection);
            // open connection to database
            connection.Open();
            // open data reader
            dataReader = command.ExecuteReader();

            while (dataReader.Read())
            {
                i++;
                dgvCustomer.Rows.Add(i, dataReader[0].ToString(), dataReader[1].ToString(), dataReader[2].ToString());
            }

            // close data reader and connection
            dataReader.Close();
            connection.Close();
        }

        private void btnCustAdd_Click(object sender, EventArgs e)
        {
            CustomerModuleForm customerModule = new CustomerModuleForm();
            customerModule.btnSave.Enabled = true;
            // can't update since creating user
            customerModule.btnUpdate.Enabled = false;
            customerModule.ShowDialog();
            // reload the users
            LoadCustomers();
        }

        private void dgvCustomer_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {
            string colName = dgvCustomer.Columns[e.ColumnIndex].Name;

            if (colName == "Edit")
            {
                // create customer module form
                CustomerModuleForm customerModule = new CustomerModuleForm();
                // get the current values of the selected row
                customerModule.lblCId.Text = dgvCustomer.Rows[e.RowIndex].Cells[1].Value.ToString();
                customerModule.txtName.Text = dgvCustomer.Rows[e.RowIndex].Cells[2].Value.ToString();
                customerModule.txtPhone.Text = dgvCustomer.Rows[e.RowIndex].Cells[3].Value.ToString();

                // display edit settings
                customerModule.btnSave.Enabled = false;
                customerModule.btnUpdate.Enabled = true;
                customerModule.ShowDialog();
            }
            else if (colName == "Delete")
            {
                if (MessageBox.Show("Are you sure you want to delete this customer?", "Delete Record", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    // open connection
                    connection.Open();
                    command = new SqlCommand("DELETE FROM [Customer] WHERE customerid LIKE '" + dgvCustomer.Rows[e.RowIndex].Cells[1].Value.ToString() + "'", connection);
                    // execute SQL command
                    command.ExecuteNonQuery();
                    // close connection
                    connection.Close();

                    MessageBox.Show("Record has been successfully deleted!");
                }
            }
            // reload the users
            LoadCustomers();
        }
    }
}
