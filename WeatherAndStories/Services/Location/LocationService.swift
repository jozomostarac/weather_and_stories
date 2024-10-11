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
}

protocol LocationService {
    func requestPermission()
    func requestLocation()
    var locationUpdates: AnyPublisher<Location, Never> { get }
    var authorizationStatusUpdates: AnyPublisher<LocationAuthorizationStatus, Never> { get }
}

class LocationServiceImpl: NSObject, LocationService, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    private let locationUpdateSubject = PassthroughSubject<CLLocation, Never>()
    private let authorizationStatusSubject = PassthroughSubject<CLAuthorizationStatus, Never>()
    
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
    
    var locationUpdates: AnyPublisher<Location, Never> {
        locationUpdateSubject
            .map { Location(lat: Double($0.coordinate.latitude), long: Double($0.coordinate.longitude)) }
            .eraseToAnyPublisher()
    }
    
    var authorizationStatusUpdates: AnyPublisher<LocationAuthorizationStatus, Never> {
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
            locationUpdateSubject.send(location)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatusSubject.send(manager.authorizationStatus)
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
