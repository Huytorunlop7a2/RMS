package com.fpt.rms.model;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

public class TableCandidate {

    private String candidateKey;

    private String name;

    private List<RestaurantTable> tables = new ArrayList<>();

    private int totalCapacity;

    private int waste;

    private int priority;

    public TableCandidate() {
    }

    /*
     * =====================================================
     * CANDIDATE KEY
     * 
     * Ví dụ:
     * bàn T01 -> "1"
     * T01 + T02 -> "1,2"
     * T01 + T02 + T03 -> "1,2,3"
     * =====================================================
     */

    public String getCandidateKey() {
        return candidateKey;
    }

    public void setCandidateKey(
            String candidateKey) {
        this.candidateKey = candidateKey;
    }

    /*
     * =====================================================
     * NAME
     * =====================================================
     */

    public String getName() {
        return name;
    }

    public void setName(
            String name) {
        this.name = name;
    }

    /*
     * =====================================================
     * TABLES
     * =====================================================
     */

    public List<RestaurantTable> getTables() {
        return tables;
    }

    public void setTables(
            List<RestaurantTable> tables) {

        this.tables = tables == null
                ? new ArrayList<>()
                : tables;
    }

    /*
     * =====================================================
     * TOTAL CAPACITY
     * =====================================================
     */

    public int getTotalCapacity() {
        return totalCapacity;
    }

    public void setTotalCapacity(
            int totalCapacity) {
        this.totalCapacity = totalCapacity;
    }

    /*
     * =====================================================
     * WASTE
     * =====================================================
     */

    public int getWaste() {
        return waste;
    }

    public void setWaste(
            int waste) {
        this.waste = waste;
    }

    /*
     * =====================================================
     * PRIORITY
     * =====================================================
     */

    public int getPriority() {
        return priority;
    }

    public void setPriority(
            int priority) {
        this.priority = priority;
    }

    /*
     * =====================================================
     * TABLE COUNT
     * =====================================================
     */

    public int getTableCount() {

        return tables == null
                ? 0
                : tables.size();
    }

    /*
     * =====================================================
     * TABLE DISPLAY
     * 
     * Ví dụ:
     * T01
     * T01 + T02
     * T01 + T02 + T06
     * =====================================================
     */

    public String getTableDisplay() {

        if (tables == null
                ||
                tables.isEmpty()) {

            return "";
        }

        return tables
                .stream()
                .map(
                        RestaurantTable::getTableNumber)
                .collect(
                        Collectors.joining(
                                " + "));
    }

    /*
     * =====================================================
     * COMBINATION
     * 
     * Không cần field combination riêng.
     * Chỉ cần số bàn > 1.
     * =====================================================
     */

    public boolean isCombination() {

        return getTableCount() > 1;
    }
}