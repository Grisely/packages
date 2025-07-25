#import "/src/cetz.typ": draw, styles, palette

#import "/src/plot.typ"

#let barchart-default-style = (
  axes: (tick: (length: 0), grid: (stroke: (dash: "dotted"))),
  bar-width: .8,
  cluster-gap: 0,
  error: (
    whisker-size: .25,
  ),
  y-inset: 1,
)

/// Draw a bar chart. A bar chart is a chart that represents data with
/// rectangular bars that grow from left to right, proportional to the values
/// they represent.
///
/// === Styling
/// Can be applied with `cetz.draw.set-style(barchart: (bar-width: 1))`.
///
/// *Root*: `barchart`.
/// #show-parameter-block("bar-width", "float", default: .8, [
///   Width of a single bar (basic) or a cluster of bars (clustered) in the plot.])
/// #show-parameter-block("y-inset", "float", default: 1, [
///   Distance of the plot data to the plot's edges on the y-axis of the plot.])
/// #show-parameter-block("cluster-gap", "float", default: 0, [
///   Spacing between bars insides a cluster.])
/// You can use any `plot` or `axes` related style keys, too.
///
/// The `barchart` function is a wrapper of the `plot` API. Arguments passed
/// to `..plot-args` are passed to the `plot.plot` function.
///
/// - data (array): Array of data rows. A row can be of type array or
///                 dictionary, with `label-key` and `value-key` being
///                 the keys to access a rows label and value(s).
///
///                 *Example*
///                 ```typc
///                 (([A], 1), ([B], 2), ([C], 3),)
///                 ```
/// - label-key (int,string): Key to access the label of a data row.
///                           This key is used as argument to the
///                           rows `.at(..)` function.
/// - value-key (int,string): Key(s) to access values of a data row.
///                           These keys are used as argument to the
///                           rows `.at(..)` function.
/// - error-key (none,int,string,array): Key(s) to access error values of a data row.
///                                These keys are used as argument to the
///                                rows `.at(..)` function.
/// - mode (string): Chart mode:
///   / basic: Single bar per data row
///   / clustered: Group of bars per data row
///   / stacked: Stacked bars per data row
///   / stacked100: Stacked bars per data row relative
///     to the sum of the row
/// - size (array): Chart size as width and height tuple in canvas unist;
///                 width can be set to `auto`.
/// - bar-style (style,function): Style or function (idx => style) to use for
///                               each bar, accepts a palette function.
/// - y-label (content,none): Y axis label
/// - x-label (content,none): x axis label
/// - labels (none,content): Legend labels per x value group
/// - ..plot-args (any): Arguments to pass to `plot.plot`
#let barchart(data,
              label-key: 0,
              value-key: 1,
              error-key: none,
              mode: "basic",
              size: (auto, 1),
              bar-style: palette.red,
              x-label: none,
              x-format: auto,
              y-label: none,
              labels: none,
              ..plot-args
              ) = {
  assert(type(label-key) in (int, str))
  if mode == "basic" {
    assert(type(value-key) in (int, str))
  } else {
    assert(type(value-key) == array)
  }

  if type(value-key) != array {
    value-key = (value-key,)
  }

  if error-key == none {
    error-key = ()
  } else if type(error-key) != array {
    error-key = (error-key,)
  }

  if type(size) != array {
    size = (size, auto)
  }
  if size.at(1) == auto {
    size.at(1) = (data.len() + 1)
  }

  let y-tic-list = data.enumerate().map(((i, t)) => {
    (data.len() - i - 1, t.at(label-key))
  })

  let x-format = x-format
  if x-format == auto {
    x-format = if mode == "stacked100" {plot.formats.decimal.with(suffix: [%])} else {auto}
  }

  data = data.enumerate().map(((i, d)) => {
    (data.len() - i - 1, value-key.map(k => d.at(k, default: 0)).flatten(), error-key.map(k => d.at(k, default: 0)).flatten())
  })

  draw.group(ctx => {
    let style = styles.resolve(ctx.style, merge: (:),
      root: "barchart", base: barchart-default-style)
    draw.set-style(..style)

    let y-inset = calc.max(style.y-inset, style.bar-width / 2)
    plot.plot(size: size,
              axis-style: "scientific-auto",
              x-label: x-label,
              x-grid: true,
              x-format: x-format,
              y-label: y-label,
              y-min: -y-inset,
              y-max: data.len() + y-inset - 1,
              y-tick-step: none,
              y-ticks: y-tic-list,
              plot-style: bar-style,
              ..plot-args,
    {
      plot.add-bar(data,
        x-key: 0,
        y-key: 1,
        error-key: if mode in ("basic", "clustered") { 2 },
        mode: mode,
        labels: labels,
        bar-width: -style.bar-width,
        cluster-gap: style.cluster-gap,
        axes: ("y", "x"))
    })
  })
}
