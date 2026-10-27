package com.fpt.rms.model;

import java.math.BigDecimal;

public class InventoryItem {

    private long inventoryItemId;
    private String name;
    private String unit;

    // Số lượng vật lý thực tế trong kho
    private BigDecimal quantity;

    // Số lượng đã giữ chỗ cho các món PENDING
    private BigDecimal reservedQuantity;

    private BigDecimal lowStockThreshold;
    private boolean active;

    public InventoryItem() {
        quantity = BigDecimal.ZERO;
        reservedQuantity = BigDecimal.ZERO;
        lowStockThreshold = BigDecimal.ZERO;
    }

    public long getInventoryItemId() {
        return inventoryItemId;
    }

    public void setInventoryItemId(long inventoryItemId) {
        this.inventoryItemId = inventoryItemId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public BigDecimal getQuantity() {
        return quantity;
    }

    public void setQuantity(BigDecimal quantity) {
        this.quantity = quantity == null
                ? BigDecimal.ZERO
                : quantity;
    }

    public BigDecimal getReservedQuantity() {
        return reservedQuantity;
    }

    public void setReservedQuantity(BigDecimal reservedQuantity) {
        this.reservedQuantity = reservedQuantity == null
                ? BigDecimal.ZERO
                : reservedQuantity;
    }

    /**
     * Available = On Hand - Reserved
     */
    public BigDecimal getAvailableQuantity() {

        BigDecimal onHand = quantity == null
                ? BigDecimal.ZERO
                : quantity;

        BigDecimal reserved = reservedQuantity == null
                ? BigDecimal.ZERO
                : reservedQuantity;

        return onHand.subtract(reserved);
    }

    public BigDecimal getLowStockThreshold() {
        return lowStockThreshold;
    }

    public void setLowStockThreshold(BigDecimal lowStockThreshold) {
        this.lowStockThreshold = lowStockThreshold == null
                ? BigDecimal.ZERO
                : lowStockThreshold;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    /**
     * Low Stock dựa trên lượng còn khả dụng,
     * không phải toàn bộ On Hand.
     */
    public boolean isLowStock() {

        if (lowStockThreshold == null) {
            return false;
        }

        return getAvailableQuantity()
                .compareTo(lowStockThreshold) <= 0;
    }
}