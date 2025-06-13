#!/bin/bash

# blur-manager - Opacity management script for Hyprland
# Usage: blur-manager [OPTION]
# Options:
#   -on     Enable opacity (uncomment all windowrulev2 lines)
#   -off    Disable opacity (comment all windowrulev2 lines, store defaults)

OPACITY_CONF="$HOME/.config/hypr/theme/opacity.conf"

# Check if opacity.conf exists
if [[ ! -f "$OPACITY_CONF" ]]; then
    echo "Error: opacity.conf not found at $OPACITY_CONF"
    echo "Please make sure the file exists or update the OPACITY_CONF variable in the script."
    exit 1
fi

# Function to show usage
show_usage() {
    echo "Usage: blur-manager [OPTION]"
    echo "Options:"
    echo "  -on     Enable opacity (uncomment all windowrulev2 lines)"
    echo "  -off    Disable opacity (comment all windowrulev2 lines)"
}

# Function to enable opacity (uncomment windowrulev2 lines)
enable_opacity() {
    echo "Enabling opacity..."
    
    # Check if backup values exist and restore them
    if grep -q "^# BACKUP:" "$OPACITY_CONF"; then
        echo "Restoring values from backup..."
        
        # Extract backup values
        local backup_op1=$(grep "^# BACKUP: opValue=" "$OPACITY_CONF" | cut -d'=' -f2)
        local backup_op2=$(grep "^# BACKUP: opValue2=" "$OPACITY_CONF" | cut -d'=' -f2)
        local backup_op3=$(grep "^# BACKUP: opValue3=" "$OPACITY_CONF" | cut -d'=' -f2)
        local backup_op4=$(grep "^# BACKUP: opValue4=" "$OPACITY_CONF" | cut -d'=' -f2)
        
        # Restore values
        sed -i "s/^\$opValue=.*$/\$opValue=$backup_op1/" "$OPACITY_CONF"
        sed -i "s/^\$opValue2=.*$/\$opValue2=$backup_op2/" "$OPACITY_CONF"
        sed -i "s/^\$opValue3=.*$/\$opValue3=$backup_op3/" "$OPACITY_CONF"
        sed -i "s/^\$opValue4=.*$/\$opValue4=$backup_op4/" "$OPACITY_CONF"
        
        # Remove backup lines
        sed -i '/^# BACKUP:/d' "$OPACITY_CONF"
        
        echo "Values restored from backup:"
        echo "  opValue:  $backup_op1"
        echo "  opValue2: $backup_op2"
        echo "  opValue3: $backup_op3"
        echo "  opValue4: $backup_op4"
    fi
    
    # Uncomment windowrulev2 lines
    sed -i 's/^#\s*windowrulev2/windowrulev2/' "$OPACITY_CONF"
    
    # Reload Hyprland config if hyprctl is available
    if command -v hyprctl &> /dev/null; then
        echo "Reloading Hyprland configuration..."
        hyprctl reload
    fi
    
    echo "Opacity enabled successfully!"
}

# Function to disable opacity (comment windowrulev2 lines and backup values)
disable_opacity() {
    echo "Disabling opacity..."
    
    # Get current values and store as backup
    local current_op1=$(grep '^\$opValue=' "$OPACITY_CONF" | cut -d'=' -f2)
    local current_op2=$(grep '^\$opValue2=' "$OPACITY_CONF" | cut -d'=' -f2)
    local current_op3=$(grep '^\$opValue3=' "$OPACITY_CONF" | cut -d'=' -f2)
    local current_op4=$(grep '^\$opValue4=' "$OPACITY_CONF" | cut -d'=' -f2)
    
    # Remove any existing backup lines first
    sed -i '/^# BACKUP:/d' "$OPACITY_CONF"
    
    # Add backup lines at the top of the file
    sed -i "1i# BACKUP: opValue4=$current_op4" "$OPACITY_CONF"
    sed -i "1i# BACKUP: opValue3=$current_op3" "$OPACITY_CONF"
    sed -i "1i# BACKUP: opValue2=$current_op2" "$OPACITY_CONF"
    sed -i "1i# BACKUP: opValue=$current_op1" "$OPACITY_CONF"
    
    # Set all opacity values to 0
    sed -i 's/^\$opValue=.*$/\$opValue=0.00/' "$OPACITY_CONF"
    sed -i 's/^\$opValue2=.*$/\$opValue2=0.00/' "$OPACITY_CONF"
    sed -i 's/^\$opValue3=.*$/\$opValue3=0.00/' "$OPACITY_CONF"
    sed -i 's/^\$opValue4=.*$/\$opValue4=0.00/' "$OPACITY_CONF"
    
    # Comment windowrulev2 lines
    sed -i 's/^windowrulev2/#windowrulev2/' "$OPACITY_CONF"
    
    echo "Values backed up and opacity disabled (all values set to 0.00)"
    
    # Reload Hyprland config if hyprctl is available
    if command -v hyprctl &> /dev/null; then
        echo "Reloading Hyprland configuration..."
        hyprctl reload
    fi
}

# Main script logic
case "$1" in
    -on)
        enable_opacity
        ;;
    -off)
        disable_opacity
        ;;
    *)
        echo "Error: Invalid option '$1'"
        echo "Valid options: -on, -off"
        show_usage
        exit 1
        ;;
esac

echo "Done!"
