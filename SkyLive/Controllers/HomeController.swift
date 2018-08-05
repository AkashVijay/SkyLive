//
//  HomeController.swift
//  SkyLive
//
//  Created by Akash Vijay on 7/14/18.
//  Copyright © 2018 Akash Vijay. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftyJSON
import CoreLocation
import AVFoundation
import UserNotifications
import StoreKit

            

class HomeController: UIViewController {
    @IBOutlet var cityNameLabel: UILabel!
    @IBOutlet var currentTempLbl: UILabel!
    @IBOutlet var summaryLbl: UILabel!
    @IBOutlet var minTempLbl: UILabel!
    @IBOutlet var maxTempLbl: UILabel!
    @IBOutlet var sunRiseLbl: UILabel!
    @IBOutlet var sunSetLbl: UILabel!
    @IBOutlet var changeOfRain : UILabel!
    @IBOutlet var dataView: UIView!
    @IBOutlet var secondDataView: UIView!
    @IBOutlet var ozoneLbl: UILabel!
    @IBOutlet var visibilityLbl: UILabel!
    @IBOutlet var windSpeedLbl: UILabel!
    @IBOutlet var uvIndexLbl: UILabel!
    @IBOutlet var locationTextField: UITextField!
    @IBOutlet var searchBtn: UIButton!
    
    var Player : AVPlayer!
    var PlayerLayer : AVPlayerLayer!
    var locationManager: CLLocationManager!
    var inputLocationName: String = ""
    
    var currentUnits: String = "" // Temp value which holds ˚F or ˚C
    
    override func viewDidLoad() {
       super.viewDidLoad()
       locationManager = CLLocationManager()
       locationManager.delegate = self
       locationManager.requestAlwaysAuthorization()
       dataView.layer.cornerRadius = 8
       secondDataView.layer.cornerRadius = 8
       defaultVideo()
       self.dataView.isHidden = true
       self.secondDataView.isHidden = true
       self.view.backgroundColor = UIColor.black
        self.locationTextField.isHidden = true
        self.locationTextField.delegate = self
        self.searchBtn.isHidden = true
        self.searchBtn.layer.cornerRadius = 10.0
    }
    //to hide status bar
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    //MARK: SearchBtn Action
    
    @IBAction func searchBtnTapped() {
        locationTextField.resignFirstResponder()
        inputLocationName = locationTextField.text!
        print("The inputLocation Name is \(inputLocationName)")
        // Get lat and long from the cityName (Api Request)
            // We need to create a function and pass cityname to it.
            // Return value is lat,long
        if (locationTextField.text?.isEmpty)! {
            SwiftSpinner.show("Please enter a valid City Name.." , animated: false).addTapHandler({SwiftSpinner.hide()}, subtitle: "Tap anywhere to dismiss this message")
        } else {
            cityName2latLong(cityName: inputLocationName)
        }
        
        // Pass that Lat and long to Default function {getApiDetails (lat,long)}
    }
    
    
    // MARK:- Alamofire
    func getApiDetails(lat:Double, long:Double) {

        if currentReachabilityStatus == .notReachable{
            let alertController = UIAlertController(title: "🔔 Notifcation 🔔", message: "This app needs internet connection.Please connect to internet and try again.", preferredStyle: .alert)
            
            let alertAction = UIAlertAction(title: "RETRY", style: .default, handler: {UIAlertAction in
                
                self.getApiDetails(lat: lat, long: long)
            })
            
            alertController.addAction(alertAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        } else {
            
            SwiftSpinner.sharedInstance.outerColor = UIColor.white
            SwiftSpinner.sharedInstance.innerColor = UIColor.white.withAlphaComponent(0.5)
            SwiftSpinner.show("Connecting to Satellite..")
            
            DispatchQueue.main.async {
                
                let apiRequest = "https://api.darksky.net/forecast/80c38af18a176ef24f19f56ade58b83d/\(lat),\(long)?exclude=minutely,hourly,flags&units=auto"
                
                print("The values of lat and long are \(lat), \(long) ==========")
                
                Alamofire.request(apiRequest).responseJSON {[weak self] response in
                    print("Result: \(response.result)")
                    SwiftSpinner.hide()
                    if #available(iOS 10.3, *) {
                        SKStoreReviewController.requestReview()
                    } else {
                        print("Rating Not asked")
                    }
                    guard let strongSelf = self else {return}
                    
                    strongSelf.dataView.isHidden = false
                    strongSelf.secondDataView.isHidden = false
                    
                    if let jsonObject = response.result.value {
                        let json = JSON(jsonObject)
                        
                        // Get the Icon value and show backgorund
                        // Write a switch case to compare all values and set the background
                        let icon = json["currently"]["icon"].stringValue
                        print("The name of the icon is::: \(icon)")
                        
                        switch icon {
                            
                        case "clear-day": strongSelf.PlayerLayer.removeFromSuperlayer()
                        strongSelf.clearDayVideo()
                        
                        case "clear-night": strongSelf.PlayerLayer.removeFromSuperlayer()
                        strongSelf.clearNightVideo()
                            
                        case "partly-cloudy-day": strongSelf.PlayerLayer.removeFromSuperlayer()
                        strongSelf.cloudyVideo()
                            
                        case "partly-cloudy-night": strongSelf.PlayerLayer.removeFromSuperlayer()
                        strongSelf.cloudyNightVideo()
                            
                        case "cloudy": strongSelf.PlayerLayer.removeFromSuperlayer()
                        strongSelf.cloudyVideo()
                            
                        case "rain": strongSelf.PlayerLayer.removeFromSuperlayer()
                        strongSelf.rainyDayVideo()
                            
                        case "sleet": strongSelf.PlayerLayer.removeFromSuperlayer()
                        strongSelf.sleetVideo()
                            
                        case "snow": strongSelf.PlayerLayer.removeFromSuperlayer()
                        strongSelf.snowVideo()
                            
                        case "wind": strongSelf.PlayerLayer.removeFromSuperlayer()
                        strongSelf.windyVideo()
                            
                        case "fog": strongSelf.PlayerLayer.removeFromSuperlayer()
                        strongSelf.fogVideo()
                            
                        case "hail": strongSelf.PlayerLayer.removeFromSuperlayer()
                        strongSelf.hailVideo()
                            
                        case "thunderstorm": strongSelf.PlayerLayer.removeFromSuperlayer()
                        strongSelf.thunderVideo()
                            
                        case "tornado": strongSelf.PlayerLayer.removeFromSuperlayer()
                        strongSelf.tornadoVideo()
                            
                        default: print("Showing default backgorund")
                        strongSelf.PlayerLayer.removeFromSuperlayer()
                        strongSelf.defaultVideo()
                            
                            
                        } // Switch closing
                        
                        //MARK:- Summary logic
                        
                        // If string contains ˚F then show units as fahrenheit else ˚C
                        // Store the value of daily summary in one variable
                        // and check if it contains ˚F
                        
                        let summaryValue = json["daily"]["summary"].stringValue
                        strongSelf.summaryLbl.text = summaryValue
                        
                        if summaryValue.contains("°F") {
                            strongSelf.currentUnits = "˚F"
                        } else {
                            strongSelf.currentUnits = "˚C"
                        }
                        
                        //MARK:- Current temparature
                        
                        let currentTemp = json["currently"]["temperature"].doubleValue
                        
                        strongSelf.currentTempLbl.text = "\(currentTemp) \(strongSelf.currentUnits)"
                        
                        //MARK:- Chance of Rain
                        let chanceOfRain = json["currently"]["precipProbability"].doubleValue
                        strongSelf.changeOfRain.text = "Chance of Precipitation: \(chanceOfRain) %"
                        
                        
                        // MARK:- TimeZone
                        
                        let timeZone = json["timezone"].stringValue
                        
                        //MARK:- sunRise,set min Max
                        
                        // Since min,max temps + sunRise and sunSet times in data Array of json
                        // And we need data[0] because, we show only current day values
                        
                        let dataArray = json["daily"]["data"].arrayValue
                        
                        for (index, dataValues) in dataArray.enumerated() {
                            if index == 0 {
                                let minTemp = dataValues["temperatureLow"].doubleValue
                                let maxTemp = dataValues["temperatureMax"].doubleValue
                                
                                strongSelf.minTempLbl.text = "Min. temp : \(minTemp) \(strongSelf.currentUnits)"
                                strongSelf.maxTempLbl.text = "Max. temp : \(maxTemp) \(strongSelf.currentUnits)"
                                
                                let sunRise = dataValues["sunriseTime"].doubleValue
                                let sunSet = dataValues["sunsetTime"].doubleValue
                                
                                // convert double to string of Date - (SunRise)
                                let rootDate = Date(timeIntervalSince1970: sunRise)
                                let dayTimePeriodFormatter = DateFormatter()
                                dayTimePeriodFormatter.dateFormat = " hh:mm a "
                                dayTimePeriodFormatter.timeZone = TimeZone(identifier: timeZone)
                                let sunriseTimeString = dayTimePeriodFormatter.string(from: rootDate)
                                strongSelf.sunRiseLbl.text = "Sunrise : \(sunriseTimeString) "
                                
                                // convert double to string of Date - (SunSet)
                                let rootDate2 = Date(timeIntervalSince1970: sunSet)
                                let dayTimePeriodFormatter2 = DateFormatter()
                                dayTimePeriodFormatter2.dateFormat = " hh:mm a "
                                dayTimePeriodFormatter2.timeZone = TimeZone(identifier: timeZone)
                                let sunSetTimeString = dayTimePeriodFormatter.string(from: rootDate2)
                                strongSelf.sunSetLbl.text = "Sunset : \(sunSetTimeString) "
                                
                            }
                        }
                        
                        
                        //MARK:- secondData
                        // Ozone, visibility, windspeed, unindex
                        
                        let ozoneValue = json["currently"]["ozone"].doubleValue
                        strongSelf.ozoneLbl.text = "Ozone : \(ozoneValue) DU"
                        
                        let visibility = json["currently"]["visibility"].doubleValue
                        if strongSelf.currentUnits == "˚F" {
                            strongSelf.visibilityLbl.text = "Visibility : \(visibility) miles"
                        } else {
                            strongSelf.visibilityLbl.text = "Visibility : \(visibility) Km"
                        }
                        
                        let uvIndex = json["currently"]["uvIndex"].intValue
                        strongSelf.uvIndexLbl.text = "UV Index : \(uvIndex)"
                        
                        let windSpeed = json["currently"]["windSpeed"].intValue
                        if strongSelf.currentUnits == "˚F" {
                            strongSelf.windSpeedLbl.text = "Wind Speed: \(windSpeed) miles/hr"
                        } else {
                            strongSelf.windSpeedLbl.text = "Wind Speed: \(windSpeed) Km/hr"
                        }
                        
                    } // jsonObject closing
                    else {
                        // This is for if any Api Error
                        SwiftSpinner.show("Unable to connect to our satellite.." , animated: false).addTapHandler({SwiftSpinner.hide()}, subtitle: "Tap anywhere to dismiss this message")
                    }
                } // completion Handler closing
            } // Dispatch Queue closing.d
        } // else Closing
    }
    
    func showAccessDeniedAlert() {
    let alertController = UIAlertController(title: "Location Permission", message: "Please grant location permission.", preferredStyle: .alert)
  
        let settingsAction = UIAlertAction(title: "Go to Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)") // Prints true
                    })
                } else {
                    
                    print("Something went wrong... Or settings updated")
                }
            }
            
        }
        alertController.addAction(settingsAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension HomeController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined: print("Unable to find your location.")
        case .authorizedAlways: print("App granted permission always.")
                                let lat = self.locationManager.location?.coordinate.latitude ?? 0.0
                                let longitude = self.locationManager.location?.coordinate.longitude ?? 0.0
        recievedLatLong(lat: lat, long: longitude) { (cityName) in
            print("The recieved city name is \(cityName).")
            self.cityNameLabel.text = cityName
            }
            getApiDetails(lat: lat, long: longitude)
        self.locationTextField.isHidden = true
        self.searchBtn.isHidden = true
        case .authorizedWhenInUse: print("App granted permission when in use.")
                                let lat = self.locationManager.location?.coordinate.latitude ?? 0.0
                                let longitude = self.locationManager.location?.coordinate.longitude ?? 0.0
        recievedLatLong(lat: lat, long: longitude) { (cityName) in
            print("The recieved city name is \(cityName).")
            self.cityNameLabel.text = cityName
            }
            getApiDetails(lat: lat, long: longitude)
        self.locationTextField.isHidden = true
        self.searchBtn.isHidden = true
        case .restricted: print("Parental Control")
        case .denied: print("User disabled access.")
            self.locationTextField.isHidden = false
            self.searchBtn.isHidden = false
                      //showAccessDeniedAlert()
        }
    }
    
}

extension HomeController {
    // VideoPlay Starting
    func fogVideo()
    {
        let URL = Bundle.main.url(forResource: "Fog", withExtension: "mp4")
        
        Player = AVPlayer.init(url: URL!)
        PlayerLayer = AVPlayerLayer(player: Player)
        PlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PlayerLayer.frame = view.layer.frame
        Player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        Player.play()
        Player.isMuted = true
        
        view.layer.insertSublayer(PlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemReachEnd(notification :)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Player.currentItem)
        
        
        // VideoPlay closing
    }
    
    
    func clearNightVideo()
    {
        let URL = Bundle.main.url(forResource: "Clear_Night", withExtension: "mp4")
        
        Player = AVPlayer.init(url: URL!)
        PlayerLayer = AVPlayerLayer(player: Player)
        PlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PlayerLayer.frame = view.layer.frame
        Player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        Player.play()
        Player.isMuted = true
        
        view.layer.insertSublayer(PlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemReachEnd(notification :)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Player.currentItem)
        
        
        // VideoPlay closing
    }
    
    
    func cloudyNightVideo()
    {
        let URL = Bundle.main.url(forResource: "Cloudy_Night", withExtension: "mp4")
        
        Player = AVPlayer.init(url: URL!)
        PlayerLayer = AVPlayerLayer(player: Player)
        PlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PlayerLayer.frame = view.layer.frame
        Player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        Player.play()
        Player.isMuted = true
        
        view.layer.insertSublayer(PlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemReachEnd(notification :)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Player.currentItem)
        
        
        // VideoPlay closing
    }
    
    
    func cloudyVideo()
    {
        let URL = Bundle.main.url(forResource: "Cloudy", withExtension: "mp4")
        
        Player = AVPlayer.init(url: URL!)
        PlayerLayer = AVPlayerLayer(player: Player)
        PlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PlayerLayer.frame = view.layer.frame
        Player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        Player.play()
        Player.isMuted = true
        
        view.layer.insertSublayer(PlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemReachEnd(notification :)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Player.currentItem)
        
        
        // VideoPlay closing
    }
    
    
    func rainyDayVideo()
    {
        let URL = Bundle.main.url(forResource: "Rainy_Day", withExtension: "mp4")
        
        Player = AVPlayer.init(url: URL!)
        PlayerLayer = AVPlayerLayer(player: Player)
        PlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PlayerLayer.frame = view.layer.frame
        Player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        Player.play()
        Player.isMuted = true
        
        view.layer.insertSublayer(PlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemReachEnd(notification :)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Player.currentItem)
        
        
        // VideoPlay closing
    }
    
    
    func tornadoVideo()
    {
        let URL = Bundle.main.url(forResource: "Tornado_New_2", withExtension: "mp4")
        
        Player = AVPlayer.init(url: URL!)
        PlayerLayer = AVPlayerLayer(player: Player)
        PlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PlayerLayer.frame = view.layer.frame
        Player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        Player.play()
        Player.isMuted = true
        
        view.layer.insertSublayer(PlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemReachEnd(notification :)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Player.currentItem)
        
        
        // VideoPlay closing
    }
    
    
    func thunderVideo()
    {
        let URL = Bundle.main.url(forResource: "Thunder", withExtension: "mp4")
        
        Player = AVPlayer.init(url: URL!)
        PlayerLayer = AVPlayerLayer(player: Player)
        PlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PlayerLayer.frame = view.layer.frame
        Player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        Player.play()
        Player.isMuted = true
        
        view.layer.insertSublayer(PlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemReachEnd(notification :)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Player.currentItem)
        
        
        // VideoPlay closing
    }
    
    
    func sleetVideo()
    {
        let URL = Bundle.main.url(forResource: "Sleet", withExtension: "mp4")
        
        Player = AVPlayer.init(url: URL!)
        PlayerLayer = AVPlayerLayer(player: Player)
        PlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PlayerLayer.frame = view.layer.frame
        Player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        Player.play()
        Player.isMuted = true
        
        view.layer.insertSublayer(PlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemReachEnd(notification :)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Player.currentItem)
        
        
        // VideoPlay closing
    }
    
    
    func hailVideo()
    {
        let URL = Bundle.main.url(forResource: "Hail_New", withExtension: "mp4")
        
        Player = AVPlayer.init(url: URL!)
        PlayerLayer = AVPlayerLayer(player: Player)
        PlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PlayerLayer.frame = view.layer.frame
        Player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        Player.play()
        Player.isMuted = true
        
        view.layer.insertSublayer(PlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemReachEnd(notification :)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Player.currentItem)
        
        
        // VideoPlay closing
    }
    
    
    func windyVideo()
    {
        let URL = Bundle.main.url(forResource: "Windy", withExtension: "mp4")
        
        Player = AVPlayer.init(url: URL!)
        PlayerLayer = AVPlayerLayer(player: Player)
        PlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PlayerLayer.frame = view.layer.frame
        Player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        Player.play()
        Player.isMuted = true
        
        view.layer.insertSublayer(PlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemReachEnd(notification :)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Player.currentItem)
        
        
        // VideoPlay closing
    }
    
    
    func snowVideo()
    {
        let URL = Bundle.main.url(forResource: "Snow", withExtension: "mp4")
        
        Player = AVPlayer.init(url: URL!)
        PlayerLayer = AVPlayerLayer(player: Player)
        PlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PlayerLayer.frame = view.layer.frame
        Player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        Player.play()
        Player.isMuted = true
        
        view.layer.insertSublayer(PlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemReachEnd(notification :)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Player.currentItem)
        
        
        // VideoPlay closing
    }
    
    
    func clearDayVideo()
    {
        let URL = Bundle.main.url(forResource: "Clear_Day", withExtension: "mp4")
        
        Player = AVPlayer.init(url: URL!)
        PlayerLayer = AVPlayerLayer(player: Player)
        PlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PlayerLayer.frame = view.layer.frame
        Player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        Player.play()
        Player.isMuted = true
        
        view.layer.insertSublayer(PlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemReachEnd(notification :)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Player.currentItem)
        
        
        // VideoPlay closing
    }
    
    func defaultVideo()
    {
        let URL = Bundle.main.url(forResource: "Default", withExtension: "mp4")
        
        Player = AVPlayer.init(url: URL!)
        PlayerLayer = AVPlayerLayer(player: Player)
        PlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PlayerLayer.frame = view.layer.frame
        Player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        Player.play()
        Player.isMuted = true
        
        view.layer.insertSublayer(PlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemReachEnd(notification :)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: Player.currentItem)
        
        // VideoPlay closing
    }
    
    
    @objc func playerItemReachEnd(notification :NSNotification)
    {
        Player.seek(to: kCMTimeZero)
    }
}

extension HomeController {
    func latLong2Name(lat: Double, long: Double, completionHandler: @escaping (String) -> ()) {
        let baseURL = "https://darksky.net/rgeo?lat=\(lat)&lon=\(long)"
        
        Alamofire.request(baseURL).responseJSON { response in
            print("Result: \(response.result)")                         // response serialization result
            
            if let jsonObject = response.result.value {
                
            var json = JSON(jsonObject)
                print("name: \(json["name"].stringValue)")
                let cityName = json["name"].stringValue
                completionHandler(cityName)
            }
        }
    }
}

extension HomeController {
    func recievedLatLong(lat:Double, long:Double, completionHandler: @escaping (String) -> ()) {
        latLong2Name(lat: lat, long: long, completionHandler: completionHandler)
    }
}


extension HomeController {
    func cityName2latLong(cityName: String) {
        let baseURL = "https://darksky.net/geo?q=\(cityName)"
        
        let encodeUrl = baseURL.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        
        Alamofire.request(encodeUrl!).responseJSON { (response) in
            
            if let jsonObject = response.result.value {
                var _json = JSON(jsonObject)
                let _lat = _json["latitude"].double ?? 0.0
                let _long = _json["longitude"].double ?? 0.0
                print("The lat, long values are", _lat, _long)
                self.getApiDetails(lat: _lat, long: _long)
            }
        }

        
    }
}

extension HomeController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}



