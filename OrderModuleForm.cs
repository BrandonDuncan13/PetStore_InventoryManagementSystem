using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.Common;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace AdriansPetStore_InventoryManagementSystem
{
    public partial class OrderModuleForm : Form
    {
        // create a connection to the database
        SqlConnection connection = new SqlConnection(@"Data Source=.;Initial Catalog=bduncan;User ID=sa;Password=***********");
        SqlCommand command = new SqlCommand();
        SqlDataReader dataReader;

        int qty = 0;

        public OrderModuleForm()
        {
            InitializeComponent();
            LoadCustomers();
            LoadProducts();
        }

        private void picBoxClose_Click(object sender, EventArgs e)
        {
            this.Dispose();
        }

        public void LoadCustomers()
        {
            int i = 0;
            // clear rows currently in the datagridview
            dgvCustomer.Rows.Clear();
            // select all users from the table
            command = new SqlCommand("SELECT customerid, name FROM [Customer] WHERE CONCAT(customerid, name, phone) LIKE '%" + txtSearchCustomer.Text + "%'", connection);
            // open connection to database
            connection.Open();
            // open data reader
            dataReader = command.ExecuteReader();

            while (dataReader.Read())
            {
                i++;
                dgvCustomer.Rows.Add(i, dataReader[0].ToString(), dataReader[1].ToString());
            }

            // close data reader and connection
            dataReader.Close();
            connection.Close();
        }

        public void LoadProducts()
        {
            int i = 0;
            // clear rows currently in the datagridview
            dgvProduct.Rows.Clear();
            // select all users from the table
            command = new SqlCommand("SELECT * FROM [Product] WHERE CONCAT(productid, name, price, description, category) LIKE '%" + txtSearchProduct.Text + "%'", connection);
            // open connection to database
            connection.Open();
            // open data reader
            dataReader = command.ExecuteReader();

            while (dataReader.Read())
            {
                i++;
                dgvProduct.Rows.Add(i, dataReader[0].ToString(), dataReader[1].ToString(), dataReader[2].ToString(), dataReader[3].ToString(), dataReader[4].ToString(), dataReader[5].ToString());
            }

            // close data reader and connection
            dataReader.Close();
            connection.Close();
        }

        private void txtSearchCustomer_TextChanged(object sender, EventArgs e)
        {
            LoadCustomers();
        }

        private void txtSearchProduct_TextChanged(object sender, EventArgs e)
        {
            LoadProducts();
        }

        private void dgvCustomer_CellClick(object sender, DataGridViewCellEventArgs e)
        {
            txtCId.Text = dgvCustomer.Rows[e.RowIndex].Cells[1].Value.ToString();
            txtCustomerName.Text = dgvCustomer.Rows[e.RowIndex].Cells[2].Value.ToString();
        }

        private void dgvProduct_CellClick(object sender, DataGridViewCellEventArgs e)
        {
            txtPId.Text = dgvProduct.Rows[e.RowIndex].Cells[1].Value.ToString();
            txtProductName.Text = dgvProduct.Rows[e.RowIndex].Cells[2].Value.ToString();
            txtPrice.Text = dgvProduct.Rows[e.RowIndex].Cells[4].Value.ToString();
        }

        private void nmrcUpDownQty_ValueChanged(object sender, EventArgs e)
        {
            GetQty();

            if (Convert.ToInt16(nmrcUpDownQty.Value) > qty)
            {
                MessageBox.Show("Instock quantity is not enough!", "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                nmrcUpDownQty.Value = qty;
                return;
            }
            if (Convert.ToInt16(nmrcUpDownQty.Value) > 0)
            {
                int total = Convert.ToInt16(txtPrice.Text) * Convert.ToInt16(nmrcUpDownQty.Value);
                txtTotal.Text = total.ToString();
            }
        }

        private void btnCreateOrder_Click(object sender, EventArgs e)
        {
            try
            {
                if (txtCId.Text == "") // check if customer selected
                {
                    MessageBox.Show("Please select a customer!", "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }
                if (txtPId.Text == "") // check if product selected
                {
                    MessageBox.Show("Please select a product!", "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                if (MessageBox.Show("Are you sure you want to create this order?", "Saving Record", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    command = new SqlCommand("INSERT INTO [Order](date,productid,customerid,qty,price,total)Values(@date,@productid,@customerid,@qty,@price,@total)", connection);
                    command.Parameters.AddWithValue("@date", dateTimePicker.Text);
                    command.Parameters.AddWithValue("@productid", Convert.ToInt32(txtPId.Text));
                    command.Parameters.AddWithValue("@customerid", Convert.ToInt32(txtCId.Text));
                    command.Parameters.AddWithValue("@qty", Convert.ToInt32(nmrcUpDownQty.Value));
                    command.Parameters.AddWithValue("@price", Convert.ToInt32(txtPrice.Text));
                    command.Parameters.AddWithValue("@total", Convert.ToInt32(txtTotal.Text));
                    // open connection to database
                    connection.Open();
                    // execute the insert
                    command.ExecuteNonQuery();
                    // close connection
                    connection.Close();
                    MessageBox.Show("Order has been successfully created.");
                }

                // update product quantity
                command = new SqlCommand("UPDATE [Product] SET qty = (qty-@qty) WHERE productid LIKE '" + txtPId.Text + "'", connection);
                command.Parameters.AddWithValue("@qty", Convert.ToInt16(nmrcUpDownQty.Value));
                // open connection to database
                connection.Open();
                // execute the insert
                command.ExecuteNonQuery();
                // close connection
                connection.Close();
                Clear();
                LoadProducts();

            }
            catch (Exception ex)
            {

                MessageBox.Show(ex.Message);
            }
        }

        public void Clear()
        {
            txtCId.Clear();
            txtCustomerName.Clear();

            txtPId.Clear();
            txtProductName.Clear();
            txtPrice.Clear();
            nmrcUpDownQty.Value = 0;
            txtTotal.Clear();
            dateTimePicker.Value = DateTime.Now;
        }

        private void btnClear_Click(object sender, EventArgs e)
        {
            Clear();
        }

        public void GetQty()
        {
            command = new SqlCommand("SELECT qty FROM [Product] WHERE productid='" + txtPId.Text + "'", connection);
            // open connection to database
            connection.Open();
            // open data reader
            dataReader = command.ExecuteReader();

            while (dataReader.Read())
            {
                qty = Convert.ToInt32(dataReader[0].ToString());
            }

            // close data reader and connection
            dataReader.Close();
            connection.Close();
        }
    }
}
