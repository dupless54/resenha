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

export function activeParticipantCount(room) {
  return Array.isArray(room?.active_participants)
    ? room.active_participants.length
    : 0;
}

export function effectiveRoomCapacity(room) {
  const capacity = Number(room?.effective_max_participants);
  return Number.isInteger(capacity) && capacity >= 2 ? capacity : null;
}

export function roomCapacityLabel(room) {
  const capacity = effectiveRoomCapacity(room);
  if (!capacity) {
    return null;
  }

  return `${activeParticipantCount(room)}/${capacity}`;
}

export function currentUserHasRoomSlot(room, userId) {
  const parsedUserId = Number(userId);
  if (!Number.isInteger(parsedUserId) || parsedUserId <= 0) {
    return false;
  }

  return (room?.active_participants ?? []).some(
    (participant) => Number(participant?.id) === parsedUserId
  );
}

export function roomCapacityBlocksJoin(room, userId) {
  // `full` is a server-authoritative snapshot for presentation only. The join
  // endpoint still performs atomic admission. A participant already holding a
  // slot must remain able to reconnect/take over that slot even at capacity.
  return room?.full === true && !currentUserHasRoomSlot(room, userId);
}
