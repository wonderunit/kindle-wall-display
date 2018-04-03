module.exports = () => {

  const moment = require('moment')

  var fs = require('fs')
  var path = require('path')
  let gm = require('gm')

  const { registerFont, createCanvas, loadImage } = require('canvas')
  
  registerFont(__dirname + '/../fonts/WonderUnitSans-Thin.ttf', {family: 'Wonder Unit Sans Thin'});
  registerFont(__dirname + '/../fonts/WonderUnitSans-Black.ttf', {family: 'Wonder Unit Sans Black'});
  const canvas = createCanvas(600, 800)
  const ctx = canvas.getContext('2d')

  ctx.fillStyle = 'white';
  ctx.fillRect(0, 0, 600, 800);

  // let img = new Image()
  // img.src = 'panic.png'



  // Write "Awesome!"
  ctx.font = '30px "Wonder Unit Sans Thin"'
  ctx.rotate(0.05)
  ctx.fillStyle = 'rgba(0,0,0,0.5)';
  ctx.fillText(moment().format('MMMM Do YYYY, h:mm:ss a'), 50, 100)

  ctx.font = '250px "Wonder Unit Sans Black"'
  //ctx.rotate(0.1)
  ctx.fillStyle = 'black';
  ctx.fillText(moment().format('h:mm'), 40, 350)

  // Draw line under text
  // var text = ctx.measureText('Awesome!')
  // ctx.strokeStyle = 'rgba(0,0,0,0.5)'
  // ctx.beginPath()
  // ctx.lineTo(50, 102)
  // ctx.lineTo(50 + text.width, 102)
  // ctx.stroke()

  let dataURL = canvas.toDataURL('image/png')
  
  var data = dataURL.replace(/^data:image\/\w+;base64,/, "");
  var buf = new Buffer(data, 'base64');
  fs.writeFile(path.join(__dirname, '..', 'output', 'testtime.png'), buf, (err) =>{
    var readStream = fs.createReadStream(path.join(__dirname, '..', 'output', 'testtime.png'))
    gm(readStream, 'testtime.png')
      .colorspace('GRAY')
      .bitdepth(4)
      .type('Grayscale')
      .dither(true)
      .write(path.join(__dirname, '..', 'output', 'time.png'), function (err) {
        if (err) console.log(err)
        //if (!err) console.log('done')
      })
  })
}
