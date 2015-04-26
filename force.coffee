WIDTH = $(window).width()
HEIGHT = $(window).height()
TIMEOUT = 200

link = gnodes = null

if localStorage.friends?
  document.getElementById('out').value = localStorage.friends

genColor = (str) ->
  Math.seedrandom(str)
  return d3.hsl(Math.random() * 360, 1, 0.5)

class Zoom
  constructor: ->
    @translation = {x: 0, y: 0}
    @center = {x: 0, y: 0}
    @factor = 1

  x: (x) -> @factor * (x - @center.x) + @center.x + @translation.x
  y: (y) -> @factor * (y - @center.y) + @center.y + @translation.y
  _x: (x) -> (x - @center.x) / @factor + @center.x - @translation.x
  _y: (y) -> (y - @center.y) / @factor + @center.y - @translation.y

  zoom: (center, factor) ->
    if factor < 1 and @factor > 1 or factor > 1 and @factor < 100
      proportion = (1 - factor) / (1 - @factor * factor)
      console.log (oldCenter = @center).x, @factor, center.x, factor
      @center = {
        x: @center.x * (1 - proportion) + center.x * proportion
        y: @center.y * (1 - proportion) + center.y * proportion
      }
      console.log 'checking identity:'
      console.log (((@center.x - oldCenter.x) * @factor) + oldCenter.x - center.x) * factor + center.x, @center.x
      @factor *= factor

zoom = new Zoom()

class Graph
  constructor: (str) ->
    @nodes = []
    @links = []

    # Parse each line
    for line in str.split '\n'
      [source, targets] = line.split ':'
      source = @createOrFindNode source.trim()
      targets = targets.split(',').map (x) -> x.trim()

      for target, i in targets
        target = @createOrFindNode target
        @connect source, target

    return true

  createOrFindNode: (name) ->
    # Look for node
    for node, i in @nodes
      if node.name is name
        return node

    # If not present, create
    node = {
      name: name
      id: @nodes.length
    }

    @nodes.push node
    return node

  connect: (a, b) ->
    # See if these nodes are already connected
    for link, i in @links
      if link.source.id is a.id and link.target.id is b.id or
         link.source.id is b.id and link.target.id is a.id
        return link

    # If not, connect them.
    link = {
      source: a
      target: b
      value: 1
    }
    @links.push link
    return link

timeout = null
svg = d3.select('#graph').append('svg')
  .attr('width', WIDTH)
  .attr('height', HEIGHT)

render = ->
  graph = new Graph document.getElementById('out').value
  force = d3.layout.force()
            .charge(-120)
            .linkDistance(50)
            .size([WIDTH, HEIGHT])

  force.nodes(graph.nodes)
       .links(graph.links)

  force.on 'tick', ->
    link.attr('x1', (d) -> zoom.x(d.source.x))
        .attr('y1', (d) -> zoom.y(d.source.y))
        .attr('x2', (d) -> zoom.x(d.target.x))
        .attr('y2', (d) -> zoom.y(d.target.y))

    gnodes.attr 'transform', (d) ->
      "translate(#{zoom.x(d.x)},#{zoom.y(d.y)})"

  force.start()
  svg.selectAll('.link').remove()
  svg.selectAll('g.gnode').remove()

  link = svg.selectAll('.link')
            .data(force.links())
            .enter().append('line')
            .attr('class', 'link')
            .style('stroke-width', (d) -> Math.sqrt(d.value))

  gnodes = svg.selectAll('g.gnode')
              .data(force.nodes())
              .enter()
              .append('g')
              .classed('gnode', true)

  node = gnodes.append('circle')
            .attr('class', 'node')
            .attr('r', 5)
            .style('fill', (d) -> genColor(d.name))
            .call(force.drag)

  labels = gnodes.append('text')
                 .text((d) -> d.name)
                 .style 'transform', 'translate(5px, 5px)'
document.getElementById('out').addEventListener 'input', ->
  if timeout?
    clearTimeout timeout
  timeout = setTimeout (->
    localStorage.friends = document.getElementById('out').value
    render()
  ), TIMEOUT


$('svg').on 'mousewheel', (event) ->
  center = {
    x: event.offsetX - zoom.translation.x
    y: event.offsetY - zoom.translation.y
  }
  if event.originalEvent.wheelDelta > 0
    zoom.zoom(center, 1.08)
  else
    zoom.zoom(center, 1 / 1.08)

  link.attr('x1', (d) -> zoom.x(d.source.x))
      .attr('y1', (d) -> zoom.y(d.source.y))
      .attr('x2', (d) -> zoom.x(d.target.x))
      .attr('y2', (d) -> zoom.y(d.target.y))

  gnodes.attr 'transform', (d) ->
    "translate(#{zoom.x(d.x)},#{zoom.y(d.y)})"

DRAG_ORIGIN = null
$('svg').on 'mousedown', (event) ->
  DRAG_ORIGIN = {
    x: event.offsetX - zoom.translation.x
    y: event.offsetY - zoom.translation.y
  }

$('svg').on 'mousemove', (event) ->
  if DRAG_ORIGIN?
    zoom.translation.x = event.offsetX - DRAG_ORIGIN.x
    zoom.translation.y = event.offsetY - DRAG_ORIGIN.y

    link.attr('x1', (d) -> zoom.x(d.source.x))
        .attr('y1', (d) -> zoom.y(d.source.y))
        .attr('x2', (d) -> zoom.x(d.target.x))
        .attr('y2', (d) -> zoom.y(d.target.y))

    gnodes.attr 'transform', (d) ->
      "translate(#{zoom.x(d.x)},#{zoom.y(d.y)})"

$('svg').on 'mouseup', (event) ->
  DRAG_ORIGIN = null

$(window).on 'resize', ->
  svg.attr('width', $(window).width())
  .attr('height', $(window).height())

render()
