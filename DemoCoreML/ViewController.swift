//
//  ViewController.swift
//  DemoCoreML
//
//  Created by Gaurav Tiwari on 29/11/18.
//  Copyright © 2018 Gaurav Tiwari. All rights reserved.
//

import UIKit
import CoreML
import AVKit
import AVFoundation
import MediaPlayer
import MobileCoreServices
import QuartzCore

class ViewController: UIViewController, UINavigationControllerDelegate {
    // E-Commerce | Amazon
    let resource1 : String = "shoes"
    let resource2 : String = "nikon"
    let resource3 : String = "Suit"
    
    // E-Commerce | Apple
    let resource4 : String = "macbook"
    let resource5 : String = "iwatch"
    
    // Food | Yelp
    let resource6 : String = "Beer"
    let resource7 : String = "Donuts"
    let resource8 : String = "Cake2"
    //        let resource9 : String = "Food1"
    //        let resource10 : String = "Pizza"
    
    // Food | Starbucks
    let resource11 : String = "Coffee1"
    let resource12 : String = "Coffee3"
    
    // Animals
    let resource13 : String = "Cats"
    let resource14 : String = "Cat2"
    let resource15 : String = "Cat3"
    let resource16 : String = "Sea"
    
    // Tourism
    let resource17 : String = "Mountains"
    let resource18 : String = "Mountains1"
    let resource19 : String = "Mountains2"
    let resource20 : String = "Tour1"
    
    let type1 : String = "mp4"
    let type2 : String = "mov"

    static let tag1 = "Animal"
    static let tag2 = "Beverage"
    static let tag3 = "Food"
    static let tag4 = "Commodity"
    static let tag5 = "Place"
    static let tag6 = "Gadget"
    static let tag7 = "Misc"

    let AnimalUrl0 = "https://www.youtube.com/results?search_query=underwater"
    let AnimalUrl = "https://www.youtube.com/results?search_query=kitten"
    let BeverageUrl0 = "https://www.google.co.in/maps/search/bars+near+foster+city/@37.5284369,-122.2959342,13z/data=!3m1!4b1"
    let PlaceUrl = "https://www.booking.com/dealspage.html"
    let FoodUrl = "https://www.yelp.com/search?find_desc=Beer&find_loc=San+Francisco%2C+CA&ns=1"
    let CommodityUrl = "https://www.amazon.com/"
//    let Misc = "https://www.youtube.com/results?search_query=kitten"

    typealias Prediction = (String, Double)

    @IBOutlet weak var view1: UIView!
    @IBOutlet weak var view2: UIView!

    @IBOutlet weak var view2Image1: UIImageView!
    @IBOutlet weak var view2Label1: UILabel!
    @IBOutlet weak var view2Image2: UIImageView!

    @IBOutlet weak var bgView1: UIView!
    @IBOutlet weak var bgView2: UIView!
    @IBOutlet weak var bgView3: UIView!
    @IBOutlet weak var bgView4: UIView!
    @IBOutlet weak var bgView5: UIView!

    @IBOutlet weak var videoTime: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var objectDetails1: UILabel!
    @IBOutlet weak var objectDetails2: UILabel!
    @IBOutlet weak var objectDetails3: UILabel!

    @IBOutlet weak var tagsDetails1: UILabel!

    @IBOutlet weak var webView: UIWebView!

    var framesDone = 0
    var frameCapturingStartTime = CACurrentMediaTime()

    var model: Inceptionv3!
    var imageNames = ["Beer.jpg", "Car.jpg", "tom-cruise.jpg", "House.jpeg", "Man.jpg", "Mug.jpg", "Pen.jpg", "Pencil.jpg", "Pen1.jpeg"]
    var counter = 0
    var player:AVPlayer?
    var playerController : AVPlayerViewController?
    var imageNameSuffix = 0
    var tagsDictionary :[String:Int] = [tag1: 0, tag2: 0, tag3: 0, tag4: 0, tag5: 0, tag7: 0]
    var timer = Timer()
    var timerAds = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        videoPlay()
        updateUIWithOutput()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func camera(_ sender: Any) {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
        present(cameraPicker, animated: true)
    }
    
    @IBAction func openLibrary(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    func updateTagsData(in: [String:Int], key: String)  {
        if (tagsDictionary.count) > 0 && tagsDictionary[key]! != 0 {
            tagsDictionary[key] = tagsDictionary[key]! + 1
        }
        else{
            tagsDictionary[key] = 1
        }
        
        print("Categories: \(tagsDictionary)")
        
        if (tagsDictionary[key] != nil){
            // Increase value
        }
        else{
            // Initait with 1
        }
    }
    
    func updateTagsUI() {
        var tagsData = ""
        
        for (key, value) in (Array(tagsDictionary).sorted {$1.1 < $0.1}) {
            if (value > 0){
                tagsData.append("\(key): \(value)\n")
            }
        }
        
        tagsDetails1.text = tagsData
        
    }
    
    func isTimeStampCurrent (timeStamp:NSDate, startTime:NSDate, endTime:NSDate)->Bool{
        if timeStamp.earlierDate(endTime as Date) == timeStamp as Date && timeStamp.laterDate(startTime as Date) == timeStamp as Date{
            return true
        }
        return false
    }
    
    func processImage (newImage: UIImage){
        imageView.image = newImage

        model = Inceptionv3()

        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        // Core ML
        guard let prediction = try? model.prediction(image: pixelBuffer!) else {
            return
        }
        
        DispatchQueue.main.async {
            self.objectDetails1.text = "\(prediction.classLabel)"
        }
        
        print("Gaurav prediction: \(prediction.classLabel)")
        
        let currentCategory = createCategoryFrom (keyword: prediction.classLabel)
        
        updateTagsData(in: tagsDictionary, key: currentCategory)
        
        updateTagsUI()
        
        let startTime = CACurrentMediaTime()

        // Give the resized input to our model.
        if let prediction = try? model.prediction(image: pixelBuffer!) {
            let top5 = top(3, prediction.classLabelProbs)
            let elapsed = CACurrentMediaTime() - startTime
            
            DispatchQueue.main.async {
                self.show(results: top5, elapsed: elapsed)
            }
        } else {
            print("BOGUS")
        }
    }
    
    func createCategoryFrom (keyword: String) -> String {
        
        var category = ""
        
//        static let tag1 = "Animal"
        if (keyword == "loggerhead, loggerhead turtle, Caretta caretta" || keyword == "tabby, tabby cat" || keyword == "Egyptian cat" || keyword == "tiger cat" || keyword == "nematode, nematode worm, roundworm") {
            category = ViewController.tag1
        }
        
//        static let tag2 = "Beverage"
        if (keyword == "beer glass" || keyword == "cup" || keyword == "espresso" || keyword == "coffee mug" || keyword == "espresso") {
            category = ViewController.tag2
        }

//        static let tag3 = "Food"
        if (keyword == "chocolate sauce, chocolate syrup" || keyword == "pretzel" || keyword == "bagel, beigel") {
            category = ViewController.tag3
        }

//        static let tag4 = "Commodity"
        if (keyword == "running shoe" || keyword == "lab coat, laboratory coat" || keyword == "Windsor tie" || keyword == "bow tie, bow-tie, bowtie" || keyword == "digital watch") {
            category = ViewController.tag4
        }

//        static let tag5 = "Place"
        if (keyword == "alp" || keyword == "promontory, headland, head, foreland" || keyword == "seashore, coast, seacoast, sea-coast" || keyword == "cliff, drop, drop-off" || keyword == "valley, vale") {
            category = ViewController.tag5
        }

        if (category.count > 0) {
            return category
        }
        else{
            return ViewController.tag7
        }

    }
    
    func loadWebView(categoryURL: String) {
        if (!self.webView.isLoading){
            let url = URL(string: categoryURL)
            let request = URLRequest(url: url!)
            DispatchQueue.main.async {
                self.webView.loadRequest(request)
            }
        }
    }
    
    func updateUIWithOutput() {
//        let myColor1 : UIColor = UIColor( red: 0.5, green: 0.5, blue:0, alpha: 1.0 )
        bgView1.layer.masksToBounds = true
//        bgView1.layer.borderColor = myColor1.cgColor
        bgView1.layer.borderColor = UIColor.black.cgColor

        bgView1.layer.borderWidth = 4.0
        
//        let myColor2 : UIColor = UIColor( red: 0.8, green: 0.8, blue:0.8, alpha: 1.0 )
        bgView2.layer.masksToBounds = true
//        bgView2.layer.borderColor = myColor2.cgColor
        bgView2.layer.borderColor = UIColor.darkGray.cgColor

        bgView2.layer.borderWidth = 4.0

//        let myColor3 : UIColor = UIColor( red: 0.4, green: 0.4, blue:0.4, alpha: 1.0 )
        bgView3.layer.masksToBounds = true
//        bgView3.layer.borderColor = myColor3.cgColor
        bgView3.layer.borderColor = UIColor.darkGray.cgColor

        bgView3.layer.borderWidth = 4.0
        
//        let myColor4 : UIColor = UIColor( red: 0.7, green: 0.7, blue:0.7, alpha: 1.0 )
        bgView4.layer.masksToBounds = true
//        bgView4.layer.borderColor = myColor4.cgColor
        bgView4.layer.borderColor = UIColor.darkGray.cgColor

        bgView4.layer.borderWidth = 4.0
        
        bgView5.layer.masksToBounds = true
        //        bgView4.layer.borderColor = myColor4.cgColor
        bgView5.layer.borderColor = UIColor.darkGray.cgColor
        
        bgView5.layer.borderWidth = 4.0
        
        view2.layer.masksToBounds = true
        view2.layer.borderColor = UIColor.black.cgColor
        view2.layer.borderWidth = 2.0
        view2.layer.cornerRadius = 4.0
    }
    
    public func top(_ k: Int, _ prob: [String: Double]) -> [(String, Double)] {
        return Array(prob.map { x in (x.key, x.value) }
            .sorted(by: { a, b -> Bool in a.1 > b.1 })
            .prefix(min(k, prob.count)))
    }

    func show(results: [Prediction], elapsed: CFTimeInterval) {
        var s: [String] = []
        for (i, pred) in results.enumerated() {
            s.append(String(format: "%d: %@ (%3.2f%%)", i + 1, pred.0, pred.1 * 100))
        }
        objectDetails2.text = s.joined(separator: "\n")
        
        let fps = self.measureFPS()
        objectDetails3.text = String(format: "Elapsed %.5f seconds - %.2f FPS", elapsed, fps)
    }

    func measureFPS() -> Double {
        // Measure how many frames were actually delivered per second.
        framesDone += 1
        let frameCapturingElapsed = CACurrentMediaTime() - frameCapturingStartTime
        let currentFPSDelivered = Double(framesDone) / frameCapturingElapsed
        if frameCapturingElapsed > 1 {
            framesDone = 0
            frameCapturingStartTime = CACurrentMediaTime()
        }
        return currentFPSDelivered
    }

    @IBAction func nextImageSelected(_ sender: Any) {
        if (counter < imageNames.count){
            let imageName = imageNames[counter]
            let image = UIImage(named: imageName)
            processImage(newImage: image!)

            counter = counter + 1
        }
        else{
            counter = 0

            let imageName = imageNames[counter]
            let image = UIImage(named: imageName)
            processImage(newImage: image!)
            
            counter = counter + 1
        }
    }
    
    @IBAction func nextVideoSelected(_ sender: Any) {

    }

    func videoPlay() {
        playerController = AVPlayerViewController()
        
        guard let path = Bundle.main.path(forResource: "Main", ofType:type1) else {
            debugPrint("video not found")
            return
        }
        
        player = AVPlayer(url: URL(fileURLWithPath: path))
        playerController!.player = player
        
        self.addChild(playerController!)
        
        view1.addSubview(playerController!.view)
        playerController!.view.frame = CGRect(x: 0, y: 0, width: 748, height: 383)
        playerController!.willMove(toParent: self)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didPlayToEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        player!.play()
        
        startTimerForFramesFetch()
        startTimerForAdsDisplay()
    }
    
    @objc func didPlayToEnd() {
        timer.invalidate()
        timerAds.invalidate()
        view2.isHidden = true
    }

    func startTimerForFramesFetch() {
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.restartFrameProcessing), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    @objc func restartFrameProcessing() {
        guard let time = player?.currentItem?.currentTime() else {
            return
        }
        
        if self.player!.currentItem?.status == AVPlayerItem.Status.readyToPlay {
            if (self.player!.currentItem?.isPlaybackLikelyToKeepUp) != nil {
                if let imageFrame = screenshotCMTime(cmTime: time){
                    saveImageToDocumentDirectory(image: imageFrame)
                    copyFromDocumentDirectory()
                }
            }
        }
    }

    func startTimerForAdsDisplay() {
        timerAds = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.restartAdsDisplay), userInfo: nil, repeats: true)
        timerAds.fire()
    }
    
    @objc func restartAdsDisplay() {
        guard (player?.currentItem?.currentTime()) != nil else {
            return
        }
        
        let currentTime: Double = player!.currentItem!.currentTime().seconds
        
        if (currentTime < 18){
            view2.isHidden = false
            view2.frame = CGRect(x: 525, y: 320, width: 186, height: 50)
            playerController!.view.addSubview(view2)
            playerController!.view.bringSubviewToFront(view2)

            view2Image1.image = UIImage(named: "1.png")
            view2Label1.text = "Similar"
            view2Image2.image = UIImage(named: "6.png")

            loadWebView(categoryURL: AnimalUrl0)
        }

        if (currentTime > 18){
            view2Image1.image = UIImage(named: "1.png")
            view2Label1.text = "More Kittens"
            view2Image2.image = UIImage(named: "6.png")

            loadWebView(categoryURL: AnimalUrl)
        }

        if (currentTime > 27){
            view2Image1.image = UIImage(named: "3.png")
            view2Label1.text = "Bars & Beer"
            view2Image2.image = UIImage(named: "6.png")

            loadWebView(categoryURL: BeverageUrl0)
        }
        
        if (currentTime > 53){
            view2Image1.image = UIImage(named: "4.jpg")
            view2Label1.text = "Explore now"
            view2Image2.image = UIImage(named: "6.png")

            loadWebView(categoryURL: PlaceUrl)
        }

        if (currentTime > 82){
            view2Image1.image = UIImage(named: "1.png")
            view2Label1.text = "Pets"
            view2Image2.image = UIImage(named: "6.png")

            loadWebView(categoryURL: AnimalUrl)
        }

        if (currentTime > 100){
            view2Image1.image = UIImage(named: "5.png")
            view2Label1.text = "Shop and see"
            view2Image2.image = UIImage(named: "6.png")

            loadWebView(categoryURL: CommodityUrl)
        }
        
        if (currentTime > 120){
            view2Image1.image = UIImage(named: "2.png")
            view2Label1.text = "More options"
            view2Image2.image = UIImage(named: "6.png")

            loadWebView(categoryURL: FoodUrl)
        }

    }

    func saveImageToDocumentDirectory(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
            return
        }
        
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return
        }
        do {
            let filename = "file\(imageNameSuffix).jpg"
            try data.write(to: directory.appendingPathComponent(filename)!)
            let path = directory.appendingPathComponent(filename)!
            print("Saving to: \(path)")

            imageNameSuffix = imageNameSuffix+1
            return
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    func screenshotCMTime(cmTime: CMTime)  -> (UIImage)? {
        var image : UIImage? = nil
        guard let player = player, let asset = player.currentItem?.asset else {
            return nil
        }
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        var timePicture = CMTime.zero
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = CMTime.zero
        imageGenerator.requestedTimeToleranceBefore = CMTime.zero
        do {
            let ref = try imageGenerator.copyCGImage(at: cmTime, actualTime: &timePicture)
            
            image = UIImage(cgImage: ref)
        }
        catch {
            error as NSError
            print(error)
        }
        return image
    }
    
    func copyFromDocumentDirectory() {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
        let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        
        if let dirPath = paths.first {
            let fileMngr = FileManager.default
            if (fileMngr.fileExists(atPath: dirPath)){
                let filename = "file\(imageNameSuffix-1).jpg"

                let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(filename)
                
                print("Getting from: \(imageURL)")

                let image    = UIImage(contentsOfFile: imageURL.path)
                imageView.image = image
//                processImage(newImage: resizeImage(image: image!)!)
                
                processImage(newImage: resizeImage2(image: image!, targetSize: CGSize(width: 299, height: 299)))

            }
        }
    }
    
    func resizeImage(image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func resizeImage2(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
//            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
            newSize = CGSize(width: 299, height: 299)

        } else {
//            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
            newSize = CGSize(width: 299, height: 299)

        }
        
        // This is the rect that we've calculated out and this is what is actually used below
//        let rect = CGRect (x: 0, y: 0, width: newSize.width, height: newSize.height)
        let rect = CGRect (x: 0, y: 0, width: 299, height: 299)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        picker.dismiss(animated: true)
        objectDetails1.text = "Analyzing Image..."
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        processImage (newImage: newImage)

    }
}

extension UIViewController: UIWebViewDelegate {
    private func webViewDidFinishLoad(_ webView: UIWebView) {
        print("Finished loading")
    }
}

extension Date {
    func dateAt(hours: Int, minutes: Int) -> Date
    {
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        
        //get the month/day/year componentsfor today's date.
        
        
        var date_components = calendar.components(
            [NSCalendar.Unit.year,
             NSCalendar.Unit.month,
             NSCalendar.Unit.day],
            from: self)
        
        //Create an NSDate for the specified time today.
        date_components.hour = hours
        date_components.minute = minutes
        date_components.second = 0
        
        let newDate = calendar.date(from: date_components)!
        return newDate
    }
}
