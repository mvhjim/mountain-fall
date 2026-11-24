extends Node
## The items the active friend carries (autoload "Inventory").
## Dialogue example:   if Inventory.has("post")   and   $> Inventory.give("car_keys")

signal changed
signal item_added(item: Item)

var items: Array[Item] = []
var _known: Dictionary = {}


## A scenario registers its items so they can be given by id.
func register(list: Array) -> void:
	for item in list:
		_known[item.id] = item


func give(id: String) -> void:
	if has(id):
		return
	var item: Item = _known.get(id)
	if item == null:
		push_error("Inventory: unknown item id '%s'. Did the scenario register it?" % id)
		return
	items.append(item)
	item_added.emit(item)
	changed.emit()
	GameState.show_toast("Got: %s" % item.display_name)


func take(id: String) -> void:
	for i in items.size():
		if items[i].id == id:
			items.remove_at(i)
			changed.emit()
			return


func has(id: String) -> bool:
	return items.any(func(it: Item) -> bool: return it.id == id)


func clear() -> void:
	items.clear()
	changed.emit()
