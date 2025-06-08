#!/bin/bash
# Base directory and subdirectory list
THEME_DIR="$HOME/.hypr-theme-manager"
SUBDIRS=("themes" "widgets" "selected")

# Function to clear screen
clear_screen() {
    clear
}

# Function to create necessary directories
create_directories() {
    [ -d "$THEME_DIR" ] || mkdir -p "$THEME_DIR"
    for subdir in "${SUBDIRS[@]}"; do
        [ -d "$THEME_DIR/$subdir" ] || mkdir -p "$THEME_DIR/$subdir"
    done
}
# Function to update existing themes with new widget
update_existing_themes_with_new_widget() {
    local widget_name="$1"
    local widget_theme_path="$2"
    
    if [ -d "$THEME_DIR/themes" ]; then
        for theme_file in "$THEME_DIR/themes"/*; do
            if [ -f "$theme_file" ]; then
                echo "" >> "$theme_file"
                echo "[$widget_name]" >> "$theme_file"
                echo "path=$widget_theme_path" >> "$theme_file"
            fi
        done
        echo "Updated existing themes with new widget '$widget_name'"
    fi
}

# Function to add widget
add_widget() {
    clear_screen
    echo "==============================================="
    echo "              WIDGET/APP THEME SETUP          "
    echo "==============================================="
    echo
    echo "For adding widget or app theme, separate your config files theme code to a theme.conf file near your config file. For example:"
    echo
    echo "Before:"
    echo "  --- waybar.conf"
    echo
    echo "After:"
    echo "  --- waybar.conf"
    echo "  --- hypr-theme.conf"
    echo
    echo "Give the hypr-theme.conf file path location. Your first theme will be the default theme,"
    echo "so we recommend you to not change your first theme file."
    echo
    echo "==============================================="
    echo
    
    # Get widget/app name
    while true; do
        read -p "Widget or app name: " widget_name
        
        # Check if name is empty
        if [ -z "$widget_name" ]; then
            echo "Error: Widget name cannot be empty. Please try again."
            continue
        fi
        
        # Check if folder exists
        if [ -d "$THEME_DIR/widgets/$widget_name" ]; then
            echo "Warning: Widget '$widget_name' already exists. Please choose a different name."
            continue
        fi
        
        # Valid name, break the loop
        break
    done
    
   # Get theme file path
    while true; do
        read -p "Theme file path location: " theme_path
        
        # Check if path is empty
        if [ -z "$theme_path" ]; then
            echo "Error: Theme file path cannot be empty. Please try again."
            continue
        fi
        
        # Expand tilde to home directory if present
        theme_path="${theme_path/#\~/$HOME}"
        
        # Check if file exists
        if [ ! -f "$theme_path" ]; then
            echo "Error: File '$theme_path' does not exist. Please check the path and try again."
            continue
        fi
        
        # Valid path, break the loop
        break
    done
    
    # Create widget directory
    mkdir -p "$THEME_DIR/widgets/$widget_name"
    
    # Copy theme file to widget directory (as default)
    if cp "$theme_path" "$THEME_DIR/widgets/$widget_name/default"; then
	    update_existing_themes_with_new_widget $widget_name $THEME_DIR/widgets/$widget_name/default
        echo
        echo "Success: Widget '$widget_name' has been added successfully!"
        echo "Theme file copied to: $THEME_DIR/widgets/$widget_name/default"
        echo
        read -p "Press Enter to continue..."
    else
        echo "Error: Failed to copy theme file. Please check permissions and try again."
        # Clean up created directory on failure
        rmdir "$THEME_DIR/widgets/$widget_name" 2>/dev/null
        echo
        read -p "Press Enter to continue..."
        return 1
    fi
}

# Function to select theme from widget
select_widget_theme() {
    local widget_name="$1"
    local widget_path="$THEME_DIR/widgets/$widget_name"
    local is_creating_theme="$2"  # Flag to check if we're in theme creation mode
    
    while true; do
        clear_screen
        echo "==============================================="
        echo "          SELECT THEME FOR: $widget_name"
        echo "==============================================="
        echo
        echo "Available themes:"
        echo
        
        local theme_count=0
        local themes=()
        
        # List available themes in widget directory
        if [ -d "$widget_path" ]; then
            for theme_file in "$widget_path"/*; do
                if [ -f "$theme_file" ]; then
                    theme_count=$((theme_count + 1))
                    theme_name=$(basename "$theme_file")
                    themes+=("$theme_name")
                    echo "  [$theme_count] $theme_name"
                fi
            done
        fi
        
        echo
        echo "  [c] Custom path"
        echo "  [b] Back to widget selection"
        echo
        echo "==============================================="
        
        read -p "Select theme or option: " selection
        
        case $selection in
            [1-9]*)
                if [ "$selection" -le "$theme_count" ] && [ "$selection" -ge 1 ]; then
                    local selected_theme="${themes[$((selection-1))]}"
                    echo "$selected_theme" > "/tmp/widget_selection_$widget_name"
                    return 0
                else
                    echo "Invalid selection. Please try again."
                    read -p "Press Enter to continue..."
                fi
                ;;
            c|C)
                echo
                read -p "Enter custom theme file path: " custom_path
                
                # Expand tilde to home directory if present
                custom_path="${custom_path/#\~/$HOME}"
                
                if [ -f "$custom_path" ]; then
                    # Check if we're in theme creation mode
                    if [ "$is_creating_theme" = "true" ]; then
                        # Use the main theme name being created
                        local custom_theme_name="$CURRENT_THEME_NAME"
                        echo "Using theme name: $custom_theme_name"
                    else
                        # Ask for theme name for this custom path (editing mode)
                        while true; do
                            read -p "Enter theme name for this custom file: " custom_theme_name
                            
                            if [ -z "$custom_theme_name" ]; then
                                echo "Error: Theme name cannot be empty. Please try again."
                                continue
                            fi
                            
                            # Check if theme already exists in widget
                            if [ -f "$widget_path/$custom_theme_name" ]; then
                                echo "Warning: Theme '$custom_theme_name' already exists in this widget. Please choose a different name."
                                continue
                            fi
                            
                            break
                        done
                    fi
                    
                    # Copy custom file to widget directory with the theme name
                    if cp "$custom_path" "$widget_path/$custom_theme_name"; then
                        echo "$custom_theme_name" > "/tmp/widget_selection_$widget_name"
                        echo "Custom theme '$custom_theme_name' added to widget '$widget_name'"
                        return 0
                    else
                        echo "Error: Failed to copy custom theme file."
                        read -p "Press Enter to continue..."
                    fi
                else
                    echo "Error: File '$custom_path' does not exist."
                    read -p "Press Enter to continue..."
                fi
                ;;
            b|B)
                return 1
                ;;
            *)
                echo "Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to create new theme
create_new_theme() {
    local theme_name="$1"
    local widget_selections=()
    
    # Set global variable for theme name to be used in custom path selection
    CURRENT_THEME_NAME="$theme_name"
    
    # Get list of widgets
    local widgets=()
    if [ -d "$THEME_DIR/widgets" ]; then
        for widget in "$THEME_DIR/widgets"/*; do
            if [ -d "$widget" ]; then
                widgets+=($(basename "$widget"))
            fi
        done
    fi
    
    if [ ${#widgets[@]} -eq 0 ]; then
        echo "No widgets found. Please add widgets first."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Widget selection loop
    while true; do
        clear_screen
        echo "==============================================="
        echo "         CREATING THEME: $theme_name"
        echo "==============================================="
        echo
        echo "Select themes for each widget:"
        echo
        
        local all_selected=true
        local selected_count=0
        
        for i in "${!widgets[@]}"; do
            local widget="${widgets[$i]}"
            local status="(unselected)"
            
            if [ -f "/tmp/widget_selection_$widget" ]; then
                local selection=$(cat "/tmp/widget_selection_$widget")
                if [[ "$selection" == /* ]]; then
                    status="(custom: $(basename "$selection"))"
                else
                    status="($selection)"
                fi
                selected_count=$((selected_count + 1))
            else
                all_selected=false
            fi
            
            echo "  [$((i+1))] $widget $status"
        done
        
        echo
        if $all_selected; then
            echo "  [c] Create theme (all widgets selected)"
        else
            echo "  [c] Create theme (${selected_count}/${#widgets[@]} selected - need all)"
        fi
        echo "  [x] Exit to main menu"
        echo
        echo "==============================================="
        
        read -p "Select widget to configure or action: " selection
        
        case $selection in
            [1-9]*)
                if [ "$selection" -le "${#widgets[@]}" ] && [ "$selection" -ge 1 ]; then
                    local widget="${widgets[$((selection-1))]}"
                    select_widget_theme "$widget" "true"  # Pass flag indicating theme creation mode
                else
                    echo "Invalid selection. Please try again."
                    read -p "Press Enter to continue..."
                fi
                ;;
            c|C)
                if $all_selected; then
                    # Create the theme
                    local theme_file="$THEME_DIR/themes/$CURRENT_THEME_NAME"
                    echo "# Theme: $CURRENT_THEME_NAME" > "$theme_file"
                    echo "# Created: $(date)" >> "$theme_file"
                    echo >> "$theme_file"
                    
                    for widget in "${widgets[@]}"; do
                        if [ -f "/tmp/widget_selection_$widget" ]; then
                            local selection=$(cat "/tmp/widget_selection_$widget")
                            echo "[$widget]" >> "$theme_file"
                            if [[ "$selection" == /* ]]; then
                                echo "path=$selection" >> "$theme_file"
                            else
                                echo "path=$THEME_DIR/widgets/$widget/$selection" >> "$theme_file"
                            fi
                            echo >> "$theme_file"
                        fi
                    done
                    
                    # Clean up temp files
                    for widget in "${widgets[@]}"; do
                        rm -f "/tmp/widget_selection_$widget"
                    done
                    
                    echo
                    echo "Success: Theme '$theme_name' created successfully!"
                    echo "Theme file: $theme_file"
                    read -p "Press Enter to continue..."
                    return 0
                else
                    echo "Error: All widgets must be selected before creating theme."
                    read -p "Press Enter to continue..."
                fi
                ;;
            x|X)
                # Clean up temp files
                for widget in "${widgets[@]}"; do
                    rm -f "/tmp/widget_selection_$widget"
                done
                return 1
                ;;
            *)
                echo "Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to copy from existing theme
copy_existing_theme() {
    while true; do
        clear_screen
        echo "==============================================="
        echo "            COPY FROM EXISTING THEME          "
        echo "==============================================="
        echo
        echo "Available themes:"
        echo
        
        local theme_count=0
        local themes=()
        
        if [ -d "$THEME_DIR/themes" ] && [ "$(ls -A "$THEME_DIR/themes" 2>/dev/null)" ]; then
            for theme_file in "$THEME_DIR/themes"/*; do
                if [ -f "$theme_file" ]; then
                    theme_count=$((theme_count + 1))
                    theme_name=$(basename "$theme_file")
                    themes+=("$theme_name")
                    echo "  [$theme_count] $theme_name"
                fi
            done
        else
            echo "  No themes found"
            echo
            read -p "Press Enter to return to main menu..."
            return 1
        fi
        
        echo
        echo "  [b] Back to theme options"
        echo
        echo "==============================================="
        
        read -p "Select theme to copy: " selection
        
        case $selection in
            [1-9]*)
                if [ "$selection" -le "$theme_count" ] && [ "$selection" -ge 1 ]; then
                    local source_theme="${themes[$((selection-1))]}"
                    
                    # Ask for new theme name
                    clear_screen
                    echo "==============================================="
                    echo "        COPYING THEME: $source_theme"
                    echo "==============================================="
                    echo
                    
                    while true; do
                        read -p "Enter new theme name: " new_theme_name
                        
                        if [ -z "$new_theme_name" ]; then
                            echo "Error: Theme name cannot be empty. Please try again."
                            continue
                        fi
                        
                        if [ -f "$THEME_DIR/themes/$new_theme_name" ]; then
                            echo "Warning: Theme '$new_theme_name' already exists. Please choose a different name."
                            continue
                        fi
                        
                        break
                    done
                    
                    # Load existing theme selections
                    local widgets=()
                    if [ -d "$THEME_DIR/widgets" ]; then
                        for widget in "$THEME_DIR/widgets"/*; do
                            if [ -d "$widget" ]; then
                                widgets+=($(basename "$widget"))
                            fi
                        done
                    fi
                    
                    # Parse existing theme file and set selections
                    local current_widget=""
                    while IFS= read -r line; do
                        if [[ $line =~ ^\[([^\]]+)\]$ ]]; then
                            current_widget="${BASH_REMATCH[1]}"
                        elif [[ $line =~ ^path=(.+)$ ]] && [ -n "$current_widget" ]; then
                            local theme_path="${BASH_REMATCH[1]}"
                            # Check if it's a widget theme path or custom path
                            if [[ "$theme_path" == "$THEME_DIR/widgets/$current_widget/"* ]]; then
                                local theme_name=$(basename "$theme_path")
                                echo "$theme_name" > "/tmp/widget_selection_$current_widget"
                            else
                                echo "$theme_path" > "/tmp/widget_selection_$current_widget"
                            fi
                        fi
                    done < "$THEME_DIR/themes/$source_theme"
                    
                    # Now use the same widget selection interface
                    create_new_theme "$new_theme_name"
                    return 0
                else
                    echo "Invalid selection. Please try again."
                    read -p "Press Enter to continue..."
                fi
                ;;
            b|B)
                return 1
                ;;
            *)
                echo "Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to edit existing theme
edit_theme() {
    while true; do
        clear_screen
        echo "==============================================="
        echo "               EDIT THEME                      "
        echo "==============================================="
        echo
        echo "Available themes:"
        echo
        
        local theme_count=0
        local themes=()
        
        if [ -d "$THEME_DIR/themes" ] && [ "$(ls -A "$THEME_DIR/themes" 2>/dev/null)" ]; then
            for theme_file in "$THEME_DIR/themes"/*; do
                if [ -f "$theme_file" ]; then
                    theme_count=$((theme_count + 1))
                    theme_name=$(basename "$theme_file")
                    themes+=("$theme_name")
                    echo "  [$theme_count] $theme_name"
                fi
            done
        else
            echo "  No themes found"
            echo
            read -p "Press Enter to return to main menu..."
            return 1
        fi
        
        echo
        echo "  [b] Back to main menu"
        echo
        echo "==============================================="
        
        read -p "Select theme to edit: " selection
        
        case $selection in
            [1-9]*)
                if [ "$selection" -le "$theme_count" ] && [ "$selection" -ge 1 ]; then
                    local theme_to_edit="${themes[$((selection-1))]}"
                    
                    # Load existing theme selections
                    local widgets=()
                    if [ -d "$THEME_DIR/widgets" ]; then
                        for widget in "$THEME_DIR/widgets"/*; do
                            if [ -d "$widget" ]; then
                                widgets+=($(basename "$widget"))
                            fi
                        done
                    fi
                    
                    # Parse existing theme file and set selections
                    local current_widget=""
                    while IFS= read -r line; do
                        if [[ $line =~ ^\[([^\]]+)\]$ ]]; then
                            current_widget="${BASH_REMATCH[1]}"
                        elif [[ $line =~ ^path=(.+)$ ]] && [ -n "$current_widget" ]; then
                            local theme_path="${BASH_REMATCH[1]}"
                            # Check if it's a widget theme path or custom path
                            if [[ "$theme_path" == "$THEME_DIR/widgets/$current_widget/"* ]]; then
                                local theme_name=$(basename "$theme_path")
                                echo "$theme_name" > "/tmp/widget_selection_$current_widget"
                            else
                                echo "$theme_path" > "/tmp/widget_selection_$current_widget"
                            fi
                        fi
                    done < "$THEME_DIR/themes/$theme_to_edit"
                    
                    # Use the same widget selection interface but for editing
                    edit_theme_widgets "$theme_to_edit"
                    return 0
                else
                    echo "Invalid selection. Please try again."
                    read -p "Press Enter to continue..."
                fi
                ;;
            b|B)
                return 1
                ;;
            *)
                echo "Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to edit theme widgets (similar to create_new_theme but for editing)
edit_theme_widgets() {
    local theme_name="$1"
    
    # Get list of widgets
    local widgets=()
    if [ -d "$THEME_DIR/widgets" ]; then
        for widget in "$THEME_DIR/widgets"/*; do
            if [ -d "$widget" ]; then
                widgets+=($(basename "$widget"))
            fi
        done
    fi
    
    if [ ${#widgets[@]} -eq 0 ]; then
        echo "No widgets found. Please add widgets first."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Widget selection loop
    while true; do
        clear_screen
        echo "==============================================="
        echo "         EDITING THEME: $theme_name"
        echo "==============================================="
        echo
        echo "Select themes for each widget:"
        echo
        
        local all_selected=true
        local selected_count=0
        
        for i in "${!widgets[@]}"; do
            local widget="${widgets[$i]}"
            local status="(unselected)"
            
            if [ -f "/tmp/widget_selection_$widget" ]; then
                local selection=$(cat "/tmp/widget_selection_$widget")
                if [[ "$selection" == /* ]]; then
                    status="(custom: $(basename "$selection"))"
                else
                    status="($selection)"
                fi
                selected_count=$((selected_count + 1))
            else
                all_selected=false
            fi
            
            echo "  [$((i+1))] $widget $status"
        done
        
        echo
        if $all_selected; then
            echo "  [s] Save changes (all widgets selected)"
        else
            echo "  [s] Save changes (${selected_count}/${#widgets[@]} selected - need all)"
        fi
        echo "  [x] Cancel and return to main menu"
        echo
        echo "==============================================="
        
        read -p "Select widget to configure or action: " selection
        
        case $selection in
            [1-9]*)
                if [ "$selection" -le "${#widgets[@]}" ] && [ "$selection" -ge 1 ]; then
                    local widget="${widgets[$((selection-1))]}"
                    select_widget_theme "$widget" "false"  # Pass false for editing mode
                else
                    echo "Invalid selection. Please try again."
                    read -p "Press Enter to continue..."
                fi
                ;;
            s|S)
                if $all_selected; then
                    # Update the theme
                    local theme_file="$THEME_DIR/themes/$theme_name"
                    echo "# Theme: $theme_name" > "$theme_file"
                    echo "# Modified: $(date)" >> "$theme_file"
                    echo >> "$theme_file"
                    
                    for widget in "${widgets[@]}"; do
                        if [ -f "/tmp/widget_selection_$widget" ]; then
                            local selection=$(cat "/tmp/widget_selection_$widget")
                            echo "[$widget]" >> "$theme_file"
                            if [[ "$selection" == /* ]]; then
                                echo "path=$selection" >> "$theme_file"
                            else
                                echo "path=$THEME_DIR/widgets/$widget/$selection" >> "$theme_file"
                            fi
                            echo >> "$theme_file"
                        fi
                    done
                    
                    # Clean up temp files
                    for widget in "${widgets[@]}"; do
                        rm -f "/tmp/widget_selection_$widget"
                    done
                    
                    echo
                    echo "Success: Theme '$theme_name' updated successfully!"
                    echo "Theme file: $theme_file"
                    read -p "Press Enter to continue..."
                    return 0
                else
                    echo "Error: All widgets must be selected before saving changes."
                    read -p "Press Enter to continue..."
                fi
                ;;
            x|X)
                # Clean up temp files
                for widget in "${widgets[@]}"; do
                    rm -f "/tmp/widget_selection_$widget"
                done
                return 1
                ;;
            *)
                echo "Invalid option. Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

add_theme() {
    while true; do
        clear_screen
        echo "==============================================="
        echo "                ADD THEME                      "
        echo "==============================================="
        echo
        echo "Choose an option:"
        echo
        echo "  [1] Copy from existing theme"
        echo "  [2] Create new theme"
        echo "  [b] Back to main menu"
        echo
        echo "==============================================="
        
        read -p "Select option (1-2, b): " option
        
        case $option in
            1)
                copy_existing_theme
                return 0
                ;;
            2)
                clear_screen
                echo "==============================================="
                echo "              CREATE NEW THEME                "
                echo "==============================================="
                echo
                
                while true; do
                    read -p "Enter theme name: " theme_name
                    
                    if [ -z "$theme_name" ]; then
                        echo "Error: Theme name cannot be empty. Please try again."
                        continue
                    fi
                    
                    if [ -f "$THEME_DIR/themes/$theme_name" ]; then
                        echo "Warning: Theme '$theme_name' already exists. Please choose a different name."
                        continue
                    fi
                    
                    break
                done
                
                create_new_theme "$theme_name"
                return 0
                ;;
            b|B)
                return 1
                ;;
            *)
                echo "Invalid option. Please choose 1, 2, or b."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Function to display main menu
main_menu() {
    clear_screen
    echo "==============================================="
    echo "           HYPR THEME MANAGER                  "
    echo "==============================================="
    echo
    
    # Display themes first
    echo "THEMES:"
    echo "-------"
    theme_count=0
    if [ -d "$THEME_DIR/themes" ] && [ "$(ls -A "$THEME_DIR/themes" 2>/dev/null)" ]; then
        for theme in "$THEME_DIR/themes"/*; do
            if [ -f "$theme" ]; then
                theme_count=$((theme_count + 1))
                theme_name=$(basename "$theme")
                echo "  [$theme_count] $theme_name"
            fi
        done
    else
        echo "  No themes found"
    fi
    echo
    
    # Display widgets
    echo "WIDGETS:"
    echo "-------"
    widget_count=0
    if [ -d "$THEME_DIR/widgets" ] && [ "$(ls -A "$THEME_DIR/widgets" 2>/dev/null)" ]; then
        for widget in "$THEME_DIR/widgets"/*; do
            if [ -d "$widget" ]; then
                widget_count=$((widget_count + 1))
                widget_name=$(basename "$widget")
                echo "  [$widget_count] $widget_name"
            fi
        done
    else
        echo "  No widgets found"
    fi
    echo
    
    # Display actions
    echo "ACTIONS:"
    echo "--------"
    echo "  [1] Add Widget"
    echo "  [2] Add Theme"
    echo "  [3] Edit Theme"
    echo "  [4] Select Theme"
    echo "  [q] Quit"
    echo
    echo "==============================================="
    
    # Wait for user input
    read -p "Choose an action (1-4, q): " action
    
    case $action in
        1)
            add_widget
            ;;
        2)
            add_theme
            ;;
        3)
            edit_theme
            ;;
        4)
            echo "Select theme function will be implemented soon..."
            read -p "Press Enter to continue..."
            ;;
        q|Q)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please choose 1, 2, 3, 4, or q."
            read -p "Press Enter to continue..."
            ;;
    esac
}

# Main execution loop
main() {
    # Clear terminal at startup
    clear_screen
    
    # Call the function to create directories
    create_directories
    
    # Main program loop
    while true; do
        main_menu
    done
}

# Run the main function
main
