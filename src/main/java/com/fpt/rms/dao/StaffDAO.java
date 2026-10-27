package com.fpt.rms.dao;

import com.fpt.rms.model.Staff;
import com.fpt.rms.util.DBContext;
import java.sql.*;

public class StaffDAO {
    public Staff findByUsername(String username) throws SQLException {
        String sql = "SELECT staff_id, full_name, username, password, role, account_status FROM staff WHERE username = ?";
        try (Connection c = DBContext.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next())
                    return null;
                Staff s = new Staff();
                s.setStaffId(rs.getLong("staff_id"));
                s.setFullName(rs.getString("full_name"));
                s.setUsername(rs.getString("username"));
                s.setPassword(rs.getString("password"));
                s.setRole(rs.getString("role"));
                s.setAccountStatus(rs.getString("account_status"));
                return s;
            }
        }
    }
}
