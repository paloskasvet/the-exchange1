extends Node

signal position_opened(ticker: String, qty: float, price: float)
signal position_closed(ticker: String, qty: float, price: float, pnl: float)
signal trade_failed(reason: String)

var holdings:  Dictionary = {}
var trade_log: Array      = []

func buy(ticker: String, shares: float) -> bool:
	if shares <= 0: emit_signal("trade_failed","Invalid quantity."); return false
	var price := MarketEngine.get_price(ticker)
	if price <= 0: emit_signal("trade_failed","Invalid asset."); return false
	var cost := price * shares * 1.001
	if cost > GameState.cash:
		emit_signal("trade_failed","Insufficient funds. Need $%.2f" % cost); return false
	GameState.add_cash(-cost)
	if ticker in holdings:
		var h = holdings[ticker]
		h["total_cost"] += price * shares
		h["qty"]        += shares
		h["avg_cost"]    = h["total_cost"] / h["qty"]
	else:
		holdings[ticker] = {"qty":shares,"avg_cost":price,"total_cost":price*shares}
	trade_log.append({"action":"BUY","ticker":ticker,"qty":shares,"price":price,"date":GameState.get_date_string()})
	emit_signal("position_opened", ticker, shares, price)
	return true

func sell(ticker: String, shares: float) -> bool:
	if shares <= 0: emit_signal("trade_failed","Invalid quantity."); return false
	if ticker not in holdings:
		emit_signal("trade_failed","No position in %s." % ticker); return false
	var h = holdings[ticker]
	if shares > h["qty"] + 0.0001:
		emit_signal("trade_failed","Only %.4f shares available." % h["qty"]); return false
	var price    = MarketEngine.get_price(ticker)
	var proceeds = price * shares * 0.999
	var pnl      = (price - h["avg_cost"]) * shares
	GameState.add_cash(proceeds)
	h["qty"]       -= shares
	h["total_cost"] = h["avg_cost"] * h["qty"]
	if h["qty"] < 0.0001: holdings.erase(ticker)
	trade_log.append({"action":"SELL","ticker":ticker,"qty":shares,"price":price,"pnl":pnl,"date":GameState.get_date_string()})
	emit_signal("position_closed", ticker, shares, price, pnl)
	return true

func grant(ticker: String, qty: float) -> void:
	if qty <= 0: return
	var price := MarketEngine.get_price(ticker)
	if ticker in holdings:
		var h = holdings[ticker]
		h["total_cost"] += price * qty
		h["qty"]        += qty
		h["avg_cost"]    = h["total_cost"] / h["qty"]
	else:
		holdings[ticker] = {"qty":qty,"avg_cost":price,"total_cost":price*qty}
	emit_signal("position_opened", ticker, qty, price)

func get_position(ticker: String) -> Dictionary:
	return holdings.get(ticker, {"qty":0.0,"avg_cost":0.0,"total_cost":0.0})

func get_total_value() -> float:
	var total := 0.0
	for t in holdings: total += holdings[t]["qty"] * MarketEngine.get_price(t)
	return total

func get_unrealized_pnl(ticker: String) -> float:
	if ticker not in holdings: return 0.0
	var h = holdings[ticker]
	return (MarketEngine.get_price(ticker) - h["avg_cost"]) * h["qty"]

func get_total_pnl() -> float:
	var total := 0.0
	for t in holdings: total += get_unrealized_pnl(t)
	return total
