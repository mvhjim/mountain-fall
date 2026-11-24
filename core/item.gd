class_name Item
extends Resource
## One inventory item. Make new items in the editor: right-click a folder,
## New Resource..., pick "Item", then fill in the fields.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
