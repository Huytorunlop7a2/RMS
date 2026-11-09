
package com.fpt.rms.dao;

import com.fpt.rms.model.Reservation;
import com.fpt.rms.util.DBContext;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class ReservationListDAO {

    private static final String FROM_SQL = " FROM reservations r "
            + "JOIN restaurant_tables t ON t.table_id = r.table_id "
            + "LEFT JOIN ("
            + "SELECT rt.reservation_id, "
            + "STRING_AGG(tb.table_number, ' + ') "
            + "WITHIN GROUP (ORDER BY tb.table_number) AS table_numbers "
            + "FROM reservation_tables rt "
            + "JOIN restaurant_tables tb ON tb.table_id = rt.table_id "
            + "GROUP BY rt.reservation_id"
            + ") x ON x.reservation_id = r.reservation_id ";

    private static final String SELECT_SQL = "SELECT "
            + "r.reservation_id, "
            + "r.table_id, "
            + "COALESCE(x.table_numbers, t.table_number) AS table_number, "
            + "r.customer_name, "
            + "r.phone_number, "
            + "r.reservation_date, "
            + "r.start_time, "
            + "r.end_time, "
            + "r.party_size, "
            + "r.status "
            + FROM_SQL;

    private String buildWhere(
            String keyword,
            LocalDate date,
            String status) {

        StringBuilder sql = new StringBuilder(" WHERE 1=1 ");

        if (keyword != null && !keyword.isBlank()) {
            sql.append(
                    "AND ("
                            + "CONVERT(VARCHAR(30), r.reservation_id) LIKE ? "
                            + "OR CONVERT(VARCHAR(30), r.table_id) LIKE ? "
                            + "OR r.customer_name LIKE ? "
                            + "OR r.phone_number LIKE ? "
                            + "OR COALESCE(x.table_numbers, t.table_number) LIKE ? "
                            + ") ");
        }

        if (date != null) {
            sql.append("AND r.reservation_date = ? ");
        }

        if (status != null && !status.isBlank()) {
            sql.append("AND r.status = ? ");
        }

        return sql.toString();
    }

    private int bindFilters(
            PreparedStatement ps,
            String keyword,
            LocalDate date,
            String status) throws SQLException {

        int index = 1;

        if (keyword != null && !keyword.isBlank()) {

            String value = "%" + keyword.trim() + "%";

            for (int i = 0; i < 5; i++) {
                ps.setString(index++, value);
            }
        }

        if (date != null) {
            ps.setDate(index++, Date.valueOf(date));
        }

        if (status != null && !status.isBlank()) {
            ps.setString(index++, status);
        }

        return index;
    }

    public List<Reservation> findPage(
            String keyword,
            LocalDate date,
            String status,
            int page,
            int pageSize) throws SQLException {

        if (page < 1) {
            page = 1;
        }

        if (pageSize != 10
                && pageSize != 20
                && pageSize != 50) {
            pageSize = 10;
        }

        int offset = (page - 1) * pageSize;

        String sql = SELECT_SQL
                + buildWhere(keyword, date, status)
                + "ORDER BY "
                + "CASE WHEN r.status IN ('CONFIRMED', 'CHECKED_IN') "
                + "THEN 0 ELSE 1 END, "
                + "CASE WHEN r.reservation_date >= CAST(GETDATE() AS DATE) "
                + "THEN 0 ELSE 1 END, "
                + "r.reservation_date, "
                + "r.start_time, "
                + "r.reservation_id "
                + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

        List<Reservation> reservations = new ArrayList<>();

        try (
                Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql)) {

            int index = bindFilters(
                    ps,
                    keyword,
                    date,
                    status);

            ps.setInt(index++, offset);
            ps.setInt(index, pageSize);

            try (ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {

                    Reservation r = new Reservation();

                    r.setReservationId(
                            rs.getLong("reservation_id"));

                    r.setTableId(
                            rs.getLong("table_id"));

                    r.setTableNumber(
                            rs.getString("table_number"));

                    r.setCustomerName(
                            rs.getString("customer_name"));

                    r.setPhoneNumber(
                            rs.getString("phone_number"));

                    r.setReservationDate(
                            rs.getDate("reservation_date").toLocalDate());

                    r.setStartTime(
                            rs.getTime("start_time").toLocalTime());

                    r.setEndTime(
                            rs.getTime("end_time").toLocalTime());

                    r.setPartySize(
                            rs.getInt("party_size"));

                    r.setStatus(
                            rs.getString("status"));

                    reservations.add(r);
                }
            }
        }

        return reservations;
    }

    public int countFiltered(
            String keyword,
            LocalDate date,
            String status) throws SQLException {

        String sql = "SELECT COUNT(*) "
                + FROM_SQL
                + buildWhere(keyword, date, status);

        try (
                Connection c = DBContext.getConnection();
                PreparedStatement ps = c.prepareStatement(sql)) {

            bindFilters(
                    ps,
                    keyword,
                    date,
                    status);

            try (ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }

        return 0;
    }
}
