const ROOM_TYPE_CAPS = Object.freeze({
  open: 50,
  stage: 200,
});

export function participantLimitForRoomType(siteLimit, roomType) {
  const typeLimit = ROOM_TYPE_CAPS[roomType] ?? ROOM_TYPE_CAPS.open;
  const parsedSiteLimit = Number(siteLimit);

  if (!Number.isInteger(parsedSiteLimit) || parsedSiteLimit < 2) {
    return typeLimit;
  }

  return Math.min(typeLimit, parsedSiteLimit);
}

export function participantValidation(siteLimit, roomType) {
  return `integer|number:2,${participantLimitForRoomType(siteLimit, roomType)}`;
}
