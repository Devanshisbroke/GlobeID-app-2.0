import React, { useState, useMemo } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Search, Plus, X, MapPin, GripVertical } from "lucide-react";
import { airports, getAirport } from "@/lib/airports";
import { useTripPlannerStore } from "@/store/tripPlannerStore";
import { cn } from "@/lib/utils";
import { haptics } from "@/utils/haptics";
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  TouchSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
} from "@dnd-kit/core";
import {
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";

/**
 * Destination row — sortable via @dnd-kit (BACKLOG D 40 leg reorder).
 *
 * The drag-handle icon (`GripVertical`) is the only listener-bound
 * region. Tap or pointer outside the handle still triggers the
 * normal remove button without contention.
 */
const SortableDestination: React.FC<{
  iata: string;
  index: number;
  total: number;
  onRemove: () => void;
}> = ({ iata, index, total, onRemove }) => {
  const apt = getAirport(iata);
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: iata });

  if (!apt) return null;

  const style: React.CSSProperties = {
    transform: CSS.Transform.toString(transform),
    transition,
    zIndex: isDragging ? 10 : 1,
    opacity: isDragging ? 0.85 : 1,
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={cn(
        "flex items-center gap-3 px-3 py-2.5 rounded-xl glass border border-border/30",
        isDragging ? "shadow-2xl ring-2 ring-[hsl(var(--p7-brand))]" : null,
      )}
    >
      <button
        type="button"
        {...listeners}
        {...attributes}
        className="touch-none px-1 py-1 -ml-1 rounded-md text-muted-foreground hover:text-foreground hover:bg-surface-overlay/40 cursor-grab active:cursor-grabbing"
        aria-label={`Reorder ${apt.city}`}
      >
        <GripVertical className="w-4 h-4" />
      </button>
      <div
        className={cn(
          "w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold",
          index === 0 ? "bg-accent text-accent-foreground" : "bg-primary/15 text-primary",
        )}
      >
        {index + 1}
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-foreground">{apt.city}</p>
        <p className="text-xs text-muted-foreground">{apt.iata} · {apt.country}</p>
      </div>
      {index < total - 1 ? (
        <div className="text-xs text-muted-foreground/60">→</div>
      ) : null}
      <button
        type="button"
        onClick={onRemove}
        className="w-6 h-6 rounded-full hover:bg-destructive/10 flex items-center justify-center transition-colors"
        aria-label={`Remove ${apt.city}`}
      >
        <X className="w-3.5 h-3.5 text-muted-foreground" />
      </button>
    </div>
  );
};

const DestinationPicker: React.FC = () => {
  const [query, setQuery] = useState("");
  const {
    currentDestinations,
    addDestination,
    removeDestination,
    reorderDestinations,
  } = useTripPlannerStore();

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 6 } }),
    useSensor(TouchSensor, {
      activationConstraint: { delay: 200, tolerance: 5 },
    }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }),
  );

  const onDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    if (!over || active.id === over.id) return;
    const fromIdx = currentDestinations.indexOf(String(active.id));
    const toIdx = currentDestinations.indexOf(String(over.id));
    if (fromIdx < 0 || toIdx < 0) return;
    reorderDestinations(fromIdx, toIdx);
    haptics.success();
  };

  const results = useMemo(() => {
    if (!query.trim()) return [];
    const q = query.toLowerCase();
    return airports
      .filter(
        (a) =>
          (a.city.toLowerCase().includes(q) ||
            a.iata.toLowerCase().includes(q) ||
            a.country.toLowerCase().includes(q)) &&
          !currentDestinations.includes(a.iata)
      )
      .slice(0, 6);
  }, [query, currentDestinations]);

  return (
    <div className="space-y-3">
      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search city or airport…"
          className="w-full pl-9 pr-3 py-2.5 rounded-xl glass border border-border/40 text-sm bg-transparent focus:outline-none focus:ring-2 focus:ring-primary/30 placeholder:text-muted-foreground"
        />
      </div>

      {/* Results */}
      <AnimatePresence>
        {results.length > 0 && (
          <motion.div
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            className="glass rounded-xl border border-border/30 overflow-hidden divide-y divide-border/20"
          >
            {results.map((apt) => (
              <button
                key={apt.iata}
                onClick={() => { addDestination(apt.iata); setQuery(""); }}
                className="w-full flex items-center gap-3 px-3 py-2.5 hover:bg-primary/5 transition-colors text-left"
              >
                <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center">
                  <MapPin className="w-4 h-4 text-primary" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-foreground truncate">{apt.city}</p>
                  <p className="text-xs text-muted-foreground">{apt.iata} · {apt.country}</p>
                </div>
                <Plus className="w-4 h-4 text-muted-foreground" />
              </button>
            ))}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Selected destinations — sortable via @dnd-kit */}
      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragEnd={onDragEnd}
      >
        <SortableContext
          items={currentDestinations}
          strategy={verticalListSortingStrategy}
        >
          <div className="space-y-1.5">
            {currentDestinations.map((iata, idx) => (
              <SortableDestination
                key={iata}
                iata={iata}
                index={idx}
                total={currentDestinations.length}
                onRemove={() => removeDestination(iata)}
              />
            ))}
          </div>
        </SortableContext>
      </DndContext>
    </div>
  );
};

export default DestinationPicker;
