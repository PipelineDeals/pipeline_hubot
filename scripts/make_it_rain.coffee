# Description:
#   None
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   make it rain - Show picture of cash money yo
#
# Author:
#  brandonhilkert

pics = [
  "http://cdn.ebaumsworld.com/mediaFiles/picture/917365/80960846.gif",
  "http://cdnl.complex.com/assets/CHANNEL_IMAGES/MUSIC/2013/02/content/tumblr_miaavvtb7j1ryfrfko1_500.gif",
  "http://cdnl.complex.com/assets/CHANNEL_IMAGES/MUSIC/2013/02/content/tumblr_mhykqaeni01ryfrfko1_500.gif",
  "http://cdnl.complex.com/assets/CHANNEL_IMAGES/MUSIC/2013/02/content/tumblr_m946h8mxxj1ryfrfko1_500.gif",
  "http://cdnl.complex.com/assets/CHANNEL_IMAGES/MUSIC/2013/02/content/plies.gif",
  "http://cdnl.complex.com/assets/CHANNEL_IMAGES/MUSIC/2013/02/content/tumblr_m9kve8uqxp1ryfrfko1_500_frdnb.gif",
  "http://cdnl.complex.com/assets/CHANNEL_IMAGES/MUSIC/2013/02/content/tumblr_mi18pprl6m1ryfrfko1_500_kxkxz.gif",
  "http://cdnl.complex.com/assets/CHANNEL_IMAGES/MUSIC/2013/02/content/tumblr_lsrkwqxgvv1qkrjt9o1_500.gif",
  "http://cdnl.complex.com/assets/CHANNEL_IMAGES/MUSIC/2013/02/content/tumblr_l0itw81tdz1qbrus1o1_500.gif",
  "http://cdnl.complex.com/assets/CHANNEL_IMAGES/MUSIC/2013/02/content/tumblr_mfm37pw71h1ryfrfko1_500.gif",
  "http://cdnl.complex.com/assets/CHANNEL_IMAGES/MUSIC/2013/02/content/tumblr_l1o5tlqktk1qbrus1o1_500_kosyh.gif",
  "http://cdnl.complex.com/assets/CHANNEL_IMAGES/MUSIC/2013/02/content/tumblr_lyq9l23z441roc353o1_400.gif",
]

module.exports = (robot) ->
  robot.hear /.*(make it rain).*/i, (msg) ->
    msg.send msg.random pics

