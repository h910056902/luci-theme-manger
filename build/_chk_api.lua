local d = require "luci.dispatcher"
print("dispatcher.entry   :", type(d.entry))
print("dispatcher.template:", type(d.template))
print("dispatcher.node    :", type(d.node))
