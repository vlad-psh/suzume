const path = require("path");
const webpack = require('webpack');

module.exports = {
  entry: [
    "./src/main.js",
    "./src/main.scss",
//    vendor: "./src/vendor.js"
  ],
  module: {
    rules: [
      {
        test: /\.vue$/,
        loader: 'vue-loader',
      },
      {
        test: /\.js$/,
        loader: 'babel-loader',
        exclude: /node_modules/
      },
      {
        test: require.resolve('jquery'),
        use: [{
          loader: 'expose-loader',
          options: 'jQuery'
        }, {
          loader: 'expose-loader',
          options: '$'
        }]
      },
    ] // end of rules
  }, // end of module
  resolve: {
    alias: {'vue$': 'vue/dist/vue.js'},
    extensions: ['*', '.js', '.vue', '.json']
  },
  plugins: [
    new webpack.ProvidePlugin({
      "$": "jquery",
      "jQuery": "jquery",
    }),
  ] // end of plugins
};
