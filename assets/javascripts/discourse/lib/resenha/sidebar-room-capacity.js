import { i18n } from "discourse-i18n";

export function sidebarRoomCapacity(room) {
  const max = Number(room?.effective_max_participants);

  if (!Number.isFinite(max) || max <= 0) {
    return null;
  }

  const count = Array.isArray(room?.active_participants)
    ? room.active_participants.length
    : 0;
  const full = room?.full === true;

  return {
    count,
    max,
    full,
    text: `${count}/${max}`,
    label: i18n(full ? "resenha.room.capacity_full" : "resenha.room.capacity", {
      count,
      max,
    }),
  };
}

export function appendSidebarRoomCapacity(title, room) {
  const capacity = sidebarRoomCapacity(room);
  return capacity ? `${title} — ${capacity.label}` : title;
}
