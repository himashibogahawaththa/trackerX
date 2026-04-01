class WebCamResponse {
  int? total;
  List<Webcams>? webcams;

  WebCamResponse({this.total, this.webcams});

  WebCamResponse.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    if (json['webcams'] != null) {
      webcams = <Webcams>[];
      json['webcams'].forEach((v) {
        webcams!.add( Webcams.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['total'] = total;
    if (webcams != null) {
      data['webcams'] = webcams!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Webcams {
  String? title;
  int? viewCount;
  int? webcamId;
  String? status;
  String? lastUpdatedOn;
  Images? images;
  Location? location;
  Player? player;

  Webcams(
      {this.title,
      this.viewCount,
      this.webcamId,
      this.status,
      this.lastUpdatedOn,
      this.images,
      this.location,
      this.player});

  Webcams.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    viewCount = json['viewCount'];
    webcamId = json['webcamId'];
    status = json['status'];
    lastUpdatedOn = json['lastUpdatedOn'];
    images = json['images'] != null ? Images.fromJson(json['images']) : null;
    location = json['location'] != null
        ? Location.fromJson(json['location'])
        : null;
    player = json['player'] != null ? Player.fromJson(json['player']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['title'] = title;
    data['viewCount'] = viewCount;
    data['webcamId'] = webcamId;
    data['status'] = status;
    data['lastUpdatedOn'] = lastUpdatedOn;
    if (images != null) {
      data['images'] = images!.toJson();
    }
    if (location != null) {
      data['location'] = location!.toJson();
    }
    if (player != null) {
      data['player'] = player!.toJson();
    }
    return data;
  }
}

class Images {
  Current? current;
  Sizes? sizes;
  Current? daylight;

  Images({this.current, this.sizes, this.daylight});

  Images.fromJson(Map<String, dynamic> json) {
    current = json['current'] != null ? Current.fromJson(json['current']) : null;
    sizes = json['sizes'] != null ? Sizes.fromJson(json['sizes']) : null;
    daylight = json['daylight'] != null
        ? Current.fromJson(json['daylight'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (current != null) {
      data['current'] = current!.toJson();
    }
    if (sizes != null) {
      data['sizes'] = sizes!.toJson();
    }
    if (daylight != null) {
      data['daylight'] = daylight!.toJson();
    }
    return data;
  }
}

class Current {
  String? icon;
  String? thumbnail;
  String? preview;

  Current({this.icon, this.thumbnail, this.preview});

  Current.fromJson(Map<String, dynamic> json) {
    icon = json['icon'];
    thumbnail = json['thumbnail'];
    preview = json['preview'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['icon'] = icon;
    data['thumbnail'] = thumbnail;
    data['preview'] = preview;
    return data;
  }
}

class Sizes {
  IconM? icon;
  IconM? thumbnail;
  IconM? preview;

  Sizes({this.icon, this.thumbnail, this.preview});

  Sizes.fromJson(Map<String, dynamic> json) {
    icon = json['icon'] != null ? IconM.fromJson(json['icon']) : null;
    thumbnail =
        json['thumbnail'] != null ? IconM.fromJson(json['thumbnail']) : null;
    preview =
        json['preview'] != null ? IconM.fromJson(json['preview']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (icon != null) {
      data['icon'] = icon!.toJson();
    }
    if (thumbnail != null) {
      data['thumbnail'] = thumbnail!.toJson();
    }
    if (preview != null) {
      data['preview'] = preview!.toJson();
    }
    return data;
  }
}

class IconM {
  int? width;
  int? height;

  IconM({this.width, this.height});

  IconM.fromJson(Map<String, dynamic> json) {
    width = json['width'];
    height = json['height'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['width'] = width;
    data['height'] = height;
    return data;
  }
}

class Location {
  String? city;
  String? region;
  String? regionCode;
  String? country;
  String? countryCode;
  String? continent;
  String? continentCode;
  double? latitude;
  double? longitude;

  Location(
      {this.city,
      this.region,
      this.regionCode,
      this.country,
      this.countryCode,
      this.continent,
      this.continentCode,
      this.latitude,
      this.longitude});

  Location.fromJson(Map<String, dynamic> json) {
    city = json['city'];
    region = json['region'];
    regionCode = json['region_code'];
    country = json['country'];
    countryCode = json['country_code'];
    continent = json['continent'];
    continentCode = json['continent_code'];
    latitude = (json['latitude'] as num?)?.toDouble();
    longitude = (json['longitude'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['city'] = city;
    data['region'] = region;
    data['region_code'] = regionCode;
    data['country'] = country;
    data['country_code'] = countryCode;
    data['continent'] = continent;
    data['continent_code'] = continentCode;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}

class Player {
  String? day;
  String? month;
  String? year;
  String? lifetime;
  String? live;

  Player({this.day, this.month, this.year, this.lifetime, this.live});

  Player.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    month = json['month'];
    year = json['year'];
    lifetime = json['lifetime'];
    live = json['live'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['day'] = day;
    data['month'] = month;
    data['year'] = year;
    data['lifetime'] = lifetime;
    data['live'] = live;
    return data;
  }
}
