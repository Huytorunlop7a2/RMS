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

    public String getCandidateKey() {
        return candidateKey;
    }

    public void setCandidateKey(String candidateKey) {
        this.candidateKey = candidateKey;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public List<RestaurantTable> getTables() {
        return tables;
    }

    public void setTables(List<RestaurantTable> tables) {
        this.tables = tables == null ? new ArrayList<>() : tables;
    }

    public int getTotalCapacity() {
        return totalCapacity;
    }

    public void setTotalCapacity(int totalCapacity) {
        this.totalCapacity = totalCapacity;
    }

    public int getWaste() {
        return waste;
    }

    public void setWaste(int waste) {
        this.waste = waste;
    }

    public int getPriority() {
        return priority;
    }

    public void setPriority(int priority) {
        this.priority = priority;
    }

    public int getTableCount() {
        return tables == null ? 0 : tables.size();
    }

    public String getTableDisplay() {
        if (tables == null || tables.isEmpty()) {
            return "";
        }
        return tables.stream().map(RestaurantTable::getTableNumber).collect(Collectors.joining(" + "));
    }

    public boolean isCombination() {
        return getTableCount() > 1;
    }
}
