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
    public partial class OrderForm : Form
    {
        // create a connection to the database
        SqlConnection connection = new SqlConnection(@"Data Source=.;Initial Catalog=bduncan;User ID=sa;Password=***********");
        SqlCommand command = new SqlCommand();
        SqlDataReader dataReader;

        public OrderForm()
        {
            InitializeComponent();
            LoadOrders();
        }
         
        public void LoadOrders()
        {
            double total = 0;
            int i = 0;
            // clear rows currently in the datagridview
            dgvOrder.Rows.Clear();
            // select all users from the table
            command = new SqlCommand("SELECT O.orderid, O.date, O.productid, P.name, O.customerid, C.name, O.qty, O.price, O.total FROM [Order] AS O JOIN [Customer] AS C ON O.customerid=C.customerid JOIN [Product] AS P ON O.productid=P.productid WHERE CONCAT(O.orderid, O.date, O.productid, P.name, O.customerid, C.name, O.qty, O.price) LIKE '%" + txtSearch.Text + "%'", connection);
            // open connection to database
            connection.Open();
            // open data reader
            dataReader = command.ExecuteReader();

            while (dataReader.Read())
            {
                i++;
                dgvOrder.Rows.Add(i, dataReader[0].ToString(), Convert.ToDateTime(dataReader[1].ToString()).ToString("MM/dd/yyyy"), dataReader[2].ToString(), dataReader[3].ToString(), dataReader[4].ToString(), dataReader[5].ToString(), dataReader[6].ToString(), dataReader[7].ToString(), dataReader[8].ToString());
                total += Convert.ToInt32(dataReader[8].ToString());
            }

            // close data reader and connection
            dataReader.Close();
            connection.Close();

            lblQty.Text = i.ToString();
            lblTotal.Text = total.ToString();
        }

        private void btnAdd_Click(object sender, EventArgs e)
        {
            OrderModuleForm orderModule = new OrderModuleForm();
            orderModule.ShowDialog();
            LoadOrders();
        }

        private void dgvOrder_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {
            string colName = dgvOrder.Columns[e.ColumnIndex].Name;

            if (colName == "Delete")
            {
                if (MessageBox.Show("Are you sure you want to delete this order?", "Delete Record", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    // open connection
                    connection.Open();
                    command = new SqlCommand("DELETE FROM [Order] WHERE orderid LIKE '" + dgvOrder.Rows[e.RowIndex].Cells[1].Value.ToString() + "'", connection);
                    // execute SQL command
                    command.ExecuteNonQuery();
                    // close connection
                    connection.Close();

                    MessageBox.Show("Record has been successfully deleted!");

                    // update product quantity
                    command = new SqlCommand("UPDATE [Product] SET qty = (qty+@qty) WHERE productid LIKE '" + dgvOrder.Rows[e.RowIndex].Cells[3].Value.ToString() + "'", connection);
                    command.Parameters.AddWithValue("@qty", Convert.ToInt16(dgvOrder.Rows[e.RowIndex].Cells[5].Value.ToString()));
                    // open connection to database
                    connection.Open();
                    // execute the insert
                    command.ExecuteNonQuery();
                    // close connection
                    connection.Close();
                }
            }
            // reload the orders
            LoadOrders();
        }

        private void txtSearch_TextChanged(object sender, EventArgs e)
        {
            LoadOrders();
        }
    }
}
