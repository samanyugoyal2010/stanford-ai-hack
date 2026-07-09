import { AudioLines } from "lucide-react";
import { cn } from "@/lib/cn";

export function Logo({ className }: { className?: string }) {
  return (
    <div className={cn("flex select-none items-center gap-2", className)}>
      <div className="grid size-7 place-items-center rounded-lg bg-accent/[0.14] text-accent">
        <AudioLines className="size-4" />
      </div>
      <span className="text-[15px] font-semibold tracking-tight text-foreground">OpenLive</span>
    </div>
  );
}
