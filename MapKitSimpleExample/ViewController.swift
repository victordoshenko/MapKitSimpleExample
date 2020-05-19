import UIKit
import MapKit

class ViewController: UIViewController, UISearchBarDelegate, MKMapViewDelegate {

    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
        
    @IBOutlet weak var mapView: MKMapView!
    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended{
            let locationInView = sender.location(in: mapView)
            let tappedCoordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)
            print(tappedCoordinate.latitude, tappedCoordinate.longitude)
            let coordinateRegion = MKCoordinateRegion(center: tappedCoordinate, latitudinalMeters: 400, longitudinalMeters: 400)
            mapView.setRegion(coordinateRegion, animated: true)
            mapView.showsUserLocation = false
            
            self.mapView.removeAnnotations(self.mapView.annotations)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = tappedCoordinate
            annotation.title = "Point"
            mapView.addAnnotation(annotation)
            
            let center = CLLocation(latitude: tappedCoordinate.latitude, longitude: tappedCoordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(center) { placemarks, error in
                guard let placemark = placemarks?.first else {
                    let errorString = error?.localizedDescription ?? "Unexpected Error"
                    print("Unable to reverse geocode the given location. Error: \(errorString)")
                    return
                }
                let reversedGeoLocation = ReversedGeoLocation(with: placemark)
                print(reversedGeoLocation.formattedAddress)
                self.addressTextField.text = reversedGeoLocation.name
                self.cityTextField.text = reversedGeoLocation.city
                self.countryTextField.text = reversedGeoLocation.country
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchBar.text ?? "") { (placemarks, error) in
            if let e = error {
                print(e.localizedDescription)
            } else
            {
                if let center = (placemarks?.first?.region as? CLCircularRegion)?.center {
                    let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
                    self.mapView.setRegion(region, animated: true)
                }
            }
        }
    }
    
    fileprivate let locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
        return manager
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        addMapTrackingButton()
        setUpMapView()
    }
    
    func addMapTrackingButton(){
        let buttonItem = MKUserTrackingButton(mapView: mapView)
        buttonItem.frame = CGRect(origin: CGPoint(x:5, y: 5), size: CGSize(width: 35, height: 35))
        mapView.addSubview(buttonItem)
    }

    func setUpMapView() {
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        currentLocation()
    }
    
    func currentLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = true
        } else {
            // Fallback on earlier versions
        }
        locationManager.startUpdatingLocation()
    }
}
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        let currentLocation = location.coordinate
        let coordinateRegion = MKCoordinateRegion(center: currentLocation, latitudinalMeters: 400, longitudinalMeters: 400)
        mapView.setRegion(coordinateRegion, animated: true)
        locationManager.stopUpdatingLocation()
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            
            guard let placemark = placemarks?.first else {
                let errorString = error?.localizedDescription ?? "Unexpected Error"
                print("Unable to reverse geocode the given location. Error: \(errorString)")
                return
            }
            
            let reversedGeoLocation = ReversedGeoLocation(with: placemark)
            print(reversedGeoLocation.formattedAddress)
            self.addressTextField.text = reversedGeoLocation.name
            self.cityTextField.text = reversedGeoLocation.city
            self.countryTextField.text = reversedGeoLocation.country
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}


struct ReversedGeoLocation {
    let name: String            // eg. Apple Inc.
    let streetName: String      // eg. Infinite Loop
    let streetNumber: String    // eg. 1
    let city: String            // eg. Cupertino
    let state: String           // eg. CA
    let zipCode: String         // eg. 95014
    let country: String         // eg. United States
    let isoCountryCode: String  // eg. US
    
    var formattedAddress: String {
        return """
        \(name)
        \(city)
        \(country)
        """
    }
    
    // Handle optionals as needed
    init(with placemark: CLPlacemark) {
        self.name           = placemark.name ?? ""
        self.streetName     = placemark.thoroughfare ?? ""
        self.streetNumber   = placemark.subThoroughfare ?? ""
        self.city           = placemark.locality ?? ""
        self.state          = placemark.administrativeArea ?? ""
        self.zipCode        = placemark.postalCode ?? ""
        self.country        = placemark.country ?? ""
        self.isoCountryCode = placemark.isoCountryCode ?? ""
    }
}

