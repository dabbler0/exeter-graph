WIDTH = 500
HEIGHT = 500

SELECTED = null

genColor = (str) ->
  Math.seedrandom(str)
  return d3.hsl(Math.random() * 360, 1, 0.5)
  #return "hsl(#{Math.round(Math.random() * 100)}%, 100%, 50%)"

d3.json 'data.json', (error, graph) ->
  force = d3.layout.force()
            .charge(-120)
            .linkDistance(50)
            .size([WIDTH, HEIGHT])

  svg = d3.select('#graph').append('svg')
      .attr('width', WIDTH)
      .attr('height', HEIGHT)

  for node, j in graph.nodes
    node.index = j

  for el, i in graph.links
    for node, j in graph.nodes
      if node.name is el.source
        graph.links[i].source = j
      if node.name is el.target
        graph.links[i].target = j

  force.nodes(graph.nodes)
       .links(graph.links)
  link = gnodes = null

  force.on 'tick', ->
    link.attr('x1', (d) -> d.source.x)
        .attr('y1', (d) -> d.source.y)
        .attr('x2', (d) -> d.target.x)
        .attr('y2', (d) -> d.target.y)

    gnodes.attr 'transform', (d) ->
      "translate(#{d.x},#{d.y})"

  force.start()

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
            .style('fill', (d) -> console.log(genColor(d.name)); genColor(d.name))
            .call(force.drag)

  labels = gnodes.append('text')
                 .text((d) -> d.name)
                 .style 'transform', 'translate(5px, 5px)'

  gnodes.on 'click', (d) ->
    if SELECTED?
      force.links().push {
        source: SELECTED.index
        target: d.index
        value: 1
      }
      console.log 'connected', SELECTED, d

      SELECTED = null
      link = svg.selectAll('.link')
            .data(force.links())
      link.enter()
            .append('line')
            .attr('class', 'link')
            .style('stroke-width', (d) -> Math.sqrt(d.value))
      link.exit().remove()
      document.getElementById('out').value = JSON.stringify graph
      force.start()
    else
      console.log 'selected', d
      SELECTED = d
