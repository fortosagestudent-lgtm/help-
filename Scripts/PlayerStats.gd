extends Node2D
## Legacy player-stat UI, currently not attached to computer.tscn. Its setters update the matching labels in its owning scene.

@export var start_money := 1000
@export var start_exp:=1000


var player_money:int:
	set(value):
		player_money = value
		%MoneyCounter.text = "Money:$ %s" %player_money

var player_exp:int:
	set(value):
		player_exp = value
		%ExpCounter.text = "Exp:$ %s" %player_exp


func _ready():
	player_money= start_money
	player_exp = start_exp


func money_change(value):
	# Accept signed changes but reject spending that would make the balance negative.

	if player_money + value >=0:
		player_money +=value
		return player_money
	else:

		%MoneyCounter.text = "Money:$ %s Not Enough Money" %player_money
		$Ui/TopLeft/VBoxContainer/MoneyCounter/MoneyMessageTimer.start()


func exp_change(value):
	# Rejected spending shows a temporary message; the timer restores the amount.

	if player_exp + value >=0:
		player_exp +=value
		return player_exp
	else:

		%ExpCounter.text = "Exp:$ %s Not Enough Experience" %player_exp
		$Ui/TopLeft/VBoxContainer/ExpCounter/ExpMessageCounter.start()


func _on_button_pressed():
	exp_change(-300)


func _on_money_message_timer_timeout() -> void:
	%MoneyCounter.text = "Money:$ %s" %player_money


func _on_exp_message_counter_timeout() -> void:
	%ExpCounter.text = "Exp:$ %s" %player_exp
