
class ServiceItem {
  final String imagePath;
  final String name;

  ServiceItem({required this.imagePath, required this.name});
}
  List<ServiceItem> servicesList = [
    ServiceItem(imagePath: 'assets/icons/Icons-01.png', name: 'Branding'),
    ServiceItem(imagePath: 'assets/icons/Icons-02.png', name: 'Digital Marketing'),
    ServiceItem(imagePath: 'assets/icons/Icons-03.png', name: 'TV Commercials'),
    ServiceItem(imagePath: 'assets/icons/Icons-04.png', name: 'Cinemas Advertising'),
    ServiceItem(imagePath: 'assets/icons/Icons-05.png', name: 'Airports Billboards'),
    ServiceItem(imagePath: 'assets/icons/Icons-06.png', name: 'Taxis & Buses Advertising'),
    ServiceItem(imagePath: 'assets/icons/Icons-07.png', name: 'Metro Stations Advertising'),
    ServiceItem(imagePath: 'assets/icons/Icons-08.png', name: 'Radio Advertising'),
    ServiceItem(imagePath: 'assets/icons/Icons-09.png', name: 'Building & Street Billboards'),
    ServiceItem(imagePath: 'assets/icons/Icons-10.png', name: 'Event Planning'),
    ServiceItem(imagePath: 'assets/icons/Icons-11.png', name: 'Influencers Marketing'),
  ];


    final Map<String, String> serviceIcons = {
    "Branding": 'assets/icons/Icons-12.png',
    "Digital Marketing": 'assets/icons/Icons-13.png',
    "TV Commercials": 'assets/icons/Icons-14.png',
    "Cinemas Advertising": 'assets/icons/Icons-15.png',
    "Airports Billboards": 'assets/icons/Icons-16.png',
    "Taxis & Buses Advertising": 'assets/icons/Icons-17.png',
    "Metro Stations Advertising": 'assets/icons/Icons-18.png',
    "Radio Advertising": 'assets/icons/Icons-19.png',
    "Building & Street Billboards": 'assets/icons/Icons-20.png',
    "Event Planning": 'assets/icons/Icons-21.png',
    "Influencers Marketing": 'assets/icons/Icons-22.png',
  };





   const List<String> companyServices = [
    'Branding',
    'Digital Marketing',
    'TV Commercials',
    'Cinemas Advertising',
    'Airports Billboards',
    'Taxis & Buses Advertising',
    'Metro Stations Advertising',
    'Radio Advertising',
    'Building & Street Billboards',
    'Event Planning',
    'Influencers Marketing',
    'Other'
  ];
   const List<String> Roles = ['As Influencer', 'As Company'];

   const List<String> PricesTag = [
  'High Price',      // Translation key for "High Price"
  'Moderate Price',  // Translation key for "Moderate Price"
  'Low Price',       // Translation key for "Low Price"
  'Special Offers'   // Translation key for "Special Offers"
];