
package com.fpt.rms.model;

import java.util.ArrayList;
import java.util.List;

public class DishGroup {
    private final long menuItemId;
    private final String menuItemName;
    private final String categoryName;
    private final List<OrderDetail> details = new ArrayList<>();
    private int totalQuantity;

    public DishGroup(OrderDetail d) {
        this.menuItemId = d.getMenuItemId();
        this.menuItemName = d.getMenuItemName();
        this.categoryName = d.getCategoryName();
    }

    public void addDetail(OrderDetail d) {
        details.add(d);
        totalQuantity += d.getQuantity();
    }

    public long getMenuItemId() {
        return menuItemId;
    }

    public String getMenuItemName() {
        return menuItemName;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public List<OrderDetail> getDetails() {
        return details;
    }

    public int getTotalQuantity() {
        return totalQuantity;
    }
}
