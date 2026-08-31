export default function roomIcon(room) {
  return room.room_type === "stage" ? "podcast" : "microphone-lines";
}

export function roomBadge(room) {
  return room.public && !room.locked ? null : "lock";
}
