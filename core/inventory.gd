extends Node
## The items each friend carries (autoload "Inventory").
## Every friend has their own pockets; "items" is always the active friend's.
## Dialogue example:   if Inventory.has("post")   and   $> Inventory.give("car_keys")

signal changed
signal item_added(item: Item)

## The active friend's items.
var items: Array[Item]:
	get:
		var id: String = GameState.active_friend
		if not _pockets.has(id):
			var empty: Array[Item] = []
			_pockets[id] = empty
		return _pockets[id]

var _pockets: Dictionary = {}
var _known: Dictionary = {}
var _recipes: Dictionary = {}


## A scenario registers its items so they can be given by id.
func register(list: Array) -> void:
	for item in list:
		_known[item.id] = item


## A scenario can say what happens when two items are combined.
## The callable runs when the player combines them (in either order).
func add_recipe(a: String, b: String, result: Callable) -> void:
	_recipes[_key(a, b)] = result


func combine(a: String, b: String) -> bool:
	var key := _key(a, b)
	if not _recipes.has(key):
		GameState.show_toast("Nothing happens.")
		return false
	_recipes[key].call()
	return true


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
	var list := items
	for i in list.size():
		if list[i].id == id:
			list.remove_at(i)
			changed.emit()
			return


func has(id: String) -> bool:
	return items.any(func(it: Item) -> bool: return it.id == id)


## Empty every friend's pockets and forget recipes (new scenario).
func clear() -> void:
	_pockets.clear()
	_recipes.clear()
	changed.emit()


func _key(a: String, b: String) -> String:
	return "%s+%s" % ([a, b] if a < b else [b, a])
