module.exports = () => {

  var fs = require('fs')
  var path = require('path')

  const { createCanvas, loadImage } = require('canvas')
  const canvas = createCanvas(600, 800)
  const ctx = canvas.getContext('2d')

  // Write "Awesome!"
  ctx.font = '30px Impact'
  ctx.rotate(0.1)
  ctx.fillText('Weather!!!', 50, 100)

  // Draw line under text
  var text = ctx.measureText('Awesome!')
  ctx.strokeStyle = 'rgba(0,0,0,0.5)'
  ctx.beginPath()
  ctx.lineTo(50, 102)
  ctx.lineTo(50 + text.width, 102)
  ctx.stroke()

  canvas.createPNGStream().pipe(fs.createWriteStream(path.join(__dirname, '..', 'output', 'weather.png')))


}
