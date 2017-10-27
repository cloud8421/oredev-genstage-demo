var data = $('.session-day')
  .map(function(i, day) {
    var dayNumber = i + 1;

    return $('.session-slot', day)
      .map(function(j, s) {
        var topics = s.className.split(" ")
          .filter(function(a) { return a.startsWith("Tag") })
          .map(function(topic) { return topic.replace("Tag", "") });

        return {speaker: $('.speaker', s).text(),
                day: dayNumber,
                title: $('.title', s).text(),
                topics: topics,
                room: $('.room', s).text(),
                starts_at: $('.time', s).text()}
      }).toArray();
  })
  .toArray();
