package com.fpt.rms.model;

import java.math.BigDecimal;

import java.util.ArrayList;
import java.util.List;

public class MenuItem {
    private long menuItemId;
    private long categoryId;
    private String categoryName;
    private String name;
    private String description;
    private BigDecimal price;
    private boolean active;
    private boolean inventoryAvailable;
    private List<RecipeIngredient> ingredients = new ArrayList<>();

    public long getMenuItemId() {
        return menuItemId;
    }

    public void setMenuItemId(long menuItemId) {
        this.menuItemId = menuItemId;
    }

    public long getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(long categoryId) {
        this.categoryId = categoryId;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public boolean isInventoryAvailable() {
        return inventoryAvailable;
    }

    public void setInventoryAvailable(boolean inventoryAvailable) {
        this.inventoryAvailable = inventoryAvailable;
    }

    public List<RecipeIngredient> getIngredients() {
        return ingredients;
    }

    public void setIngredients(List<RecipeIngredient> ingredients) {
        this.ingredients = ingredients == null ? new ArrayList<>() : ingredients;
    }

    public boolean isRecipeConfigured() {
        return ingredients != null && !ingredients.isEmpty();
    }

    public boolean isAvailableForCustomer() {
        return active && inventoryAvailable;
    }
}
