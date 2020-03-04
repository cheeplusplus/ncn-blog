---
title: MyConbook
tags: MyConbook
date: September 6, 2012
---
This is my long running main project - [MyConbook](http://myconbook.net/). It’s a mobile app that takes convention conbook information and makes it easily accessable on your phone. I started the project when I found it silly that I had to keep checking a paper book for simple information, but if I wanted it on my phone I had to open a large PDF.

<img src="assets/2012-09-06-myconbook/1.png" class="img-fluid">

<img src="assets/2012-09-06-myconbook/2.png" class="img-fluid">

<img src="assets/2012-09-06-myconbook/3.png" class="img-fluid">

It consists of three parts:

* The backend, which is a Python script that creates the data files based on information given by the conventions

* The [Android version](https://play.google.com/store/apps/details?id=net.myconbook.android), which was the first version, showing everything from the convention schedule to the restaurant guide and more. An important feature of this was to be able to work entirely offline, which was successful at [Oklacon](http://oklacon.com/), where there was no cell reception at the convention proper. This is done entirely in Java.

* The [Mobile Web version](http://m.myconbook.net/), which I threw together given the lack of an iOS version. It shows all of the same data as the Android version, and can be accessed from any web enabled device. It uses Jquery Mobile UI for the user interface, backbone.js to handle the data model, Handlebars.js for templating, and is written in Coffeescript.

Next up (which is what I plan on documenting in the coming weeks) is a real iOS version. I bought my first real Mac (the new Retina MacBook Pro) to replace my bulky HP laptop, with the intent of getting this finished. My next post will likely be some time this weekend documenting where I am with this. Short version is I’m still tackling the UI in Xcode.
