//
//  LocationService.swift
//  WeatherAndStories
//
//  Created by Jozo Mostarac on 11.10.2024..
//

import CoreLocation
import Combine
import Dependencies

enum LocationAuthorizationStatus: Equatable {
    case unknown, approved, denied
}

struct Location: Equatable, Codable {
    let lat: Double
    let long: Double
    let cityName: String?
}

protocol LocationService {
    func requestPermission()
    func requestLocation()
    var locationUpdates: AnyPublisher<Location, Error> { get }
    var authorizationStatusUpdates: AnyPublisher<LocationAuthorizationStatus, Error> { get }
}

class LocationServiceImpl: NSObject, LocationService, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    private let locationUpdateSubject = PassthroughSubject<(CLLocation, cityName: String?), Error>()
    private let authorizationStatusSubject = PassthroughSubject<CLAuthorizationStatus, Error>()
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    var locationUpdates: AnyPublisher<Location, Error> {
        locationUpdateSubject
            .map {
                Location(
                    lat: Double($0.0.coordinate.latitude),
                    long: Double($0.0.coordinate.longitude),
                    cityName: $0.1
                )
            }
            .eraseToAnyPublisher()
    }
    
    var authorizationStatusUpdates: AnyPublisher<LocationAuthorizationStatus, Error> {
        authorizationStatusSubject
            .map { status in
                switch status {
                case .authorizedAlways, .authorizedWhenInUse:
                    return LocationAuthorizationStatus.approved
                case .denied, .restricted:
                    return LocationAuthorizationStatus.denied
                default:
                    return LocationAuthorizationStatus.unknown
                }
            }
            .eraseToAnyPublisher()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            getCityName(from: location) { [weak self] cityName in
                self?.locationUpdateSubject.send((location, cityName))
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatusSubject.send(manager.authorizationStatus)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationUpdateSubject.send(completion: .failure(error))
    }
    
    private func getCityName(from location: CLLocation, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            if let placemark = placemarks?.first, let city = placemark.locality {
                completion(city)
                return
            }
            completion(nil)
        }
    }
}



// MARK: - TCA Dependencies

private enum LocationServiceKey: DependencyKey {
    static let liveValue: LocationService = LocationServiceImpl()
}

extension DependencyValues {
    var locationService: LocationService {
        get { self[LocationServiceKey.self] }
        set { self[LocationServiceKey.self] = newValue }
    }
}
