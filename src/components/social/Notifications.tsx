import React from "react";
import { motion } from "framer-motion";
import { useSocialStore } from "@/store/socialStore";
import { cn } from "@/lib/utils";
import { Heart, UserPlus, MessageCircle, TrendingUp, Check } from "lucide-react";

const iconMap = { like: Heart, follow: UserPlus, comment: MessageCircle, trending: TrendingUp };
const colorMap = { like: "text-destructive", follow: "text-primary", comment: "text-accent", trending: "text-neon-amber" };

const Notifications: React.FC = () => {
  const { notifications, users, markNotificationRead } = useSocialStore();

  return (
    <div className="space-y-1.5">
      {notifications.map((notif, i) => {
        const user = users.find((u) => u.id === notif.fromUserId);
        const Icon = iconMap[notif.type];
        return (
          <motion.div
            key={notif.id}
            initial={{ opacity: 0, x: -12 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: i * 0.05 }}
            onClick={() => markNotificationRead(notif.id)}
            className={cn(
              "flex items-center gap-3 px-3 py-2.5 rounded-xl cursor-pointer transition-colors",
              notif.read ? "opacity-60" : "glass border border-border/30"
            )}
          >
            <div className="relative">
              <img src={user?.avatar || ""} alt="" className="w-9 h-9 rounded-full object-cover" />
              <div className={cn("absolute -bottom-0.5 -right-0.5 w-4 h-4 rounded-full bg-background flex items-center justify-center")}>
                <Icon className={cn("w-2.5 h-2.5", colorMap[notif.type])} />
              </div>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm text-foreground">
                <span className="font-semibold">{user?.name}</span> {notif.message}
              </p>
              <p className="text-[10px] text-muted-foreground">{notif.createdAt}</p>
            </div>
            {!notif.read && <div className="w-2 h-2 rounded-full bg-primary" />}
          </motion.div>
        );
      })}
    </div>
  );
};

export default Notifications;
