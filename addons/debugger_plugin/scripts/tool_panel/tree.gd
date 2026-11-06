@tool
extends Tree


signal watch_toggled(index: int, enabled: bool)
signal watch_removed(index: int)


const COLORS: Array[Color] = [Color("378ADD"), Color("BA7517"), Color("1D9E75"), Color("D4537E")] 

const COL_NAME: int = 0
const COL_VALUE: int = 1
const COL_REMOVE: int = 2


var _rows: Dictionary = {}


func _ready() -> void:
    columns = 3
    hide_root = true
    select_mode = Tree.SELECT_ROW
    column_titles_visible = true
    set_column_title(COL_NAME, "Property")
    set_column_title(COL_VALUE, "Value")

    set_column_expand(COL_NAME, true)
    set_column_expand(COL_VALUE, false)
    set_column_custom_minimum_width(COL_VALUE, 90)
    set_column_expand(COL_REMOVE, false)
    set_column_custom_minimum_width(COL_REMOVE, 32)

    item_edited.connect(_on_item_edited)
    button_clicked.connect(_on_button_pressed)


func set_watches(watches: Array) -> void:
    clear()
    _rows.clear()

    var root: TreeItem = create_item()
    var groups: Dictionary = {}

    for i in watches.size():
        var w: Dictionary = watches[i]

        var group: TreeItem = groups.get(w.path)
        if group == null:
            group = create_item(root)
            group.set_text(COL_NAME, _node_label(w.path))

            if has_theme_icon("Node2D", "EditorIcons") and w.prop is Node2D:
                group.set_icon(COL_NAME, get_theme_icon("Node2D", "EditorIcons"))
            elif has_theme_icon("Control", "EditorIcons") and w.prop is Control:
                group.set_icon(COL_NAME, get_theme_icon("CircleShape2D", "EditorIcons"))
            elif has_theme_icon("Node3D", "EditorIcons") and w.prop is Node3D:
                group.set_icon(COL_NAME, get_theme_icon("Node3D", "EditorIcons"))
            elif has_theme_icon("Node", "EditorIcons") and w.prop is Node:
                group.set_icon(COL_NAME, get_theme_icon("Node", "EditorIcons"))
            
            group.set_selectable(COL_NAME, false)
            group.set_selectable(COL_VALUE, false)
            group.set_selectable(COL_REMOVE, false)
            groups[w.path] = group
        
        var item: TreeItem = create_item(group)
        
        item.set_cell_mode(COL_NAME, TreeItem.CELL_MODE_CHECK)
        item.set_editable(COL_NAME, true)
        item.set_checked(COL_NAME, w.get("enabled", true))
        item.set_text(COL_NAME, w.prop)
        item.set_icon(COL_NAME, _swatch(COLORS[i % COLORS.size()]))
        item.set_tooltip_text(COL_NAME, "%s : %s" % [w.path, w.prop])

        item.set_text(COL_VALUE, "-")
        item.set_text_alignment(COL_VALUE, HORIZONTAL_ALIGNMENT_RIGHT)
        
        if has_theme_icon("Remove", "EditorIcons"):
            item.add_button(COL_REMOVE, get_theme_icon("Remove", "EditorIcons"), 0, false, "Rimuovi")
        
        item.set_metadata(COL_NAME, i)
        _rows[i] = item


func set_value(index: int, text: String) -> void:
    var item: TreeItem = _rows.get(index)

    if item:
        item.set_text(COL_VALUE, text)


func _on_item_edited() -> void:
    _emit_edit(get_edited(), get_edited_column())


func _emit_edit(item: TreeItem, column: int) -> void:
    if item != null and column == COL_NAME:
        watch_toggled.emit(int(item.get_metadata(COL_NAME)), item.is_checked(COL_NAME))


func _on_button_pressed(item: TreeItem, column: int, _id: int, _mouse_button: int) -> void:
    if column == COL_REMOVE:
        watch_removed.emit(int(item.get_metadata(COL_NAME)))


func _node_label(path: String) -> String:
    return "(root of the scene)" if path == "." else path


func _swatch(color: Color) -> Texture2D:
    var image := Image.create(12, 12, false, Image.FORMAT_RGBA8)
    image.fill(color)

    return ImageTexture.create_from_image(image)