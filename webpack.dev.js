const path = require("path");
const common = require("./webpack.common");
const merge = require("webpack-merge");

module.exports = merge(common, {
  mode: "development",
//  entry: [
//    './js/main.js',
//    'webpack-dev-server/client?http://edu.fc/',
//  ],
  output: {
//    filename: "[name].bundle.js",
//    path: path.resolve(__dirname, "dist")

    path: path.resolve(__dirname, './public/build2'),
    publicPath: '/build/',
    filename: 'main.js'
  },
  plugins: [
  ],
  module: {
    rules: [
      {
        test: /\.scss$/,
        use: [
          "style-loader", //3. Inject styles into DOM
          "css-loader", //2. Turns css into commonjs
          "sass-loader" //1. Turns sass into css
        ]
      }
    ]
  },
  devServer: {
//    historyApiFallback: true,
//    noInfo: true,
//    overlay: true,
    compress: true,
    disableHostCheck: true,
//    allowedHosts: ['tulip.fc', 'jkb.fruitcode.net'],
    public: 'jkb.fruitcode.net',
    sockHost: 'jkb.fruitcode.net',
    sockPort: 80
  }
});
