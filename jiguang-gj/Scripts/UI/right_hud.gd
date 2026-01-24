extends CanvasLayer


func _process(_delta: float) -> void:
	$hp.value = $"..".health
	$mp.value = $"..".energy
	if $"..".rebound:
		$rebound.visible = true
	else:
		$rebound.visible = false
	if $"..".guard:
		$guard.visible = true
	else:
		$guard.visible = false
