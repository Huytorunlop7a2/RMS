package com.fpt.rms.model;

public class TableAdjacencyOverride {
    private long tableId1;
    private String tableNumber1;
    private long tableId2;
    private String tableNumber2;
    private boolean allowed;

    public TableAdjacencyOverride() {
    }

    public long getTableId1() {
        return tableId1;
    }

    public void setTableId1(long tableId1) {
        this.tableId1 = tableId1;
    }

    public String getTableNumber1() {
        return tableNumber1;
    }

    public void setTableNumber1(String tableNumber1) {
        this.tableNumber1 = tableNumber1;
    }

    public long getTableId2() {
        return tableId2;
    }

    public void setTableId2(long tableId2) {
        this.tableId2 = tableId2;
    }

    public String getTableNumber2() {
        return tableNumber2;
    }

    public void setTableNumber2(String tableNumber2) {
        this.tableNumber2 = tableNumber2;
    }

    public boolean isAllowed() {
        return allowed;
    }

    public void setAllowed(boolean allowed) {
        this.allowed = allowed;
    }

    public String getPairName() {
        return tableNumber1 + " ↔ " + tableNumber2;
    }

    public String getRuleLabel() {
        return allowed ? "Cho phép ghép" : "Chặn ghép";
    }
}
