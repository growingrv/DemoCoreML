# DemoCoreML
A sample app which **demonstrates machine learning usage & utilizes image recognition.**

## Functional details:
* The app captures screenshots from a playing video.
* The app processes the screenshots and fetches objects from the image.
* The app records, maps and stores the objects from image.
* Once objects are available, there can be many operations which can be done using those objects. 
* As an extra feature, app shows ads *OR* articles *OR* search results based on the object being identified. 
* Example: For object "alps", user sees Booking.com home page, For object "cats" user sees youtube video recommendations. 

## Implementation details:
* Video playback happens over **AVPlayer**. The video is placed locally in the app.
* The app captures screenshots from the playing video in regular and defined intervals.
* The app uses **Google's Inceptionv3 model** for image recognition. 

## Screenshots

***
<img src = "Screens/1.png">

***
<img src = "Screens/2.png">

***
<img src = "Screens/3.png">

***
<img src = "Screens/4.png">

***
<img src = "Screens/5.png">

***
<img src = "Screens/6.png">

***
<img src = "Screens/7.png">

***
<img src = "Screens/8.png">

***
<img src = "Screens/9.png">

***
<img src = "Screens/10.png">
