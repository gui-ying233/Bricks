local b = require('bricks')

local document = b:new('<div>/div >')

local ele = document:getElementsByTagName('div')[1]

print(ele.tagName)
