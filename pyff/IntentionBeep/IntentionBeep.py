# IntentionBeep.py -
# MSK, 2018
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#
#

import pygame, os
from FeedbackBase.PygameFeedback import PygameFeedback
from __builtin__ import str
from collections import deque
import winsound

class IntentionBeep(PygameFeedback):

    def init(self):

        PygameFeedback.init(self)
        
        ########################################################################
        
        self.FPS = 200
        #self.screenPos = [1280, 0]
        #self.screenSize = [1280, 1024]
        self.screenPos = [0, 0]
        self.screenSize = [1280, 1024]
        self.screen_center = [self.screenSize[0]/2,self.screenSize[1]/2]
        self.caption = "IntentionBeep"
        
        self.spot_size = (self.screenSize[1]/6, self.screenSize[1]/6)
        self.spot_states = ('','yellow')
        
        self.background_color = [127, 127, 127]
        self.text_fontsize = 75
        self.text_color = [64,64,64]
        self.char_fontsize = 100
        self.char_color = [0,0,0]
        
        self.prompt_text = 'Were you about to press?'
        self.pause_text = 'Paused. Press pedal to continue...'
        self.paused = True
        self.on_trial = False
        
        ########################################################################
        
        self.duration_spot_yellow = 500
        self.duration_cross = 2500
        self.min_waittime = 1500
        
        self.marker_keyboard_press = 255-199
        self.marker_quit = 255-255
        self.marker_base_start = 255-10
        self.marker_base_interruption = 255-20
        self.marker_trial_end = 255-30
        
        self.marker_identifier = {self.marker_base_interruption : 'beep move silent',
                                  self.marker_base_interruption+1 : 'beep move',
                                  self.marker_base_interruption+2 : 'beep idle'}
        
        ########################################################################
        # MAIN PARAMETERS TO BE SET IN MATLAB
        
        self.listen_to_keyboard = 1
        self.make_interruptions = 1
        self.pause_every_x_events = 6
        self.end_after_x_events = 6
        self.end_pause_counter_type = 1 # 1 - button presses, 2 - move lights, 3 - idle lights, 4 - seconds
        self.bci_delayed_idle = 0
        self.trial_assignment = [2,2,2,2,2,2,2] # 1 - move, 2 - idle
        self.ir_idle_waittime = [3000.0,3000.0,3000.0,3000.0,3000.0,3000.0,3000.0]
        
        ########################################################################  


    def pre_mainloop(self):
        PygameFeedback.pre_mainloop(self)
        self.send_parallel(255) # reset all pins to on
        self.font_text = pygame.font.Font(None, self.text_fontsize)
        self.font_char = pygame.font.Font(None, self.char_fontsize)
        self.trial_counter = 0
        self.block_counter = 0
        self.move_counter = 0
        self.idle_counter = 0
        self.pedalpress_counter = 0
        self.time_recording_start = pygame.time.get_ticks() 
        if self.make_interruptions:
            self.queue_waittime = deque(self.ir_idle_waittime)
            self.queue_trial = deque(self.trial_assignment)
        self.reset_trial_states()
        self.load_images()
        self.on_pause()
        
        
    def reset_trial_states(self):
        self.time_trial_end = float('infinity')
        self.time_trial_start = float('infinity')
        self.yellow_until = float('infinity')
        self.yellow_on = False
        self.already_interrupted = False
        self.already_pressed = False
        self.already_moved = False
        self.this_premature = False
        self.last_cl_output = 1
        

    def post_mainloop(self):
        PygameFeedback.post_mainloop(self)
    
   
    def on_pause(self):
        self.log('Paused. Waiting for participant to continue...')
        self.time_trial_start = float('infinity')
        self.paused = True
        self.on_trial = False
    
    
    def unpause(self):
        self.log('Starting block '+str(self.block_counter+1))
        now = pygame.time.get_ticks()
        self.paused = False
        self.time_trial_start = now + self.duration_cross
        self.trial_counter -= 1 # ugly hack


    def tick(self):
        now = pygame.time.get_ticks()
        if self.listen_to_keyboard:
            self.on_keyboard_event()
        if not self.paused:
            if now > self.time_trial_end: # it's time to end trial
                self.on_trial = False
                self.reset_trial_states()
                self.trial_counter += 1
                self.send_parallel(self.marker_trial_end)
                self.time_trial_start = now + self.duration_cross
                self.time_trial_end = float('infinity')
            if now > self.time_trial_start: # it's time to start the next trial
                # however, first check if it's time ...
                # ... to end
                if self.count_events() >= self.end_after_x_events:
                    self.send_parallel(self.marker_quit)
                    self.on_stop()
                # ... or to pause
                elif self.count_events() - self.pause_every_x_events*self.block_counter >= self.pause_every_x_events:
                    self.block_counter += 1
                    self.on_pause()
                # otherwise, start new trial
                else:
                    self.on_trial = True
                    self.this_trial()
                    self.send_parallel(self.this_start_marker)
                    self.time_trial_start = float('infinity')
            # for testing purposes and/or interrupting without listening to classifier
            if not self.bci_delayed_idle:
                if self.on_trial and not self.already_interrupted and not self.already_pressed and not self.already_moved and self.make_interruptions:
                    if self.this_trial_type==2 and now > self.this_start_time + self.this_idle_waittime:
                        self.do_interruption()
            # update spot
            self.change_spot()
        self.present_stimulus()
    
    
    def count_events(self):
        if self.end_pause_counter_type==1:
            nr_events = self.pedalpress_counter
        elif self.end_pause_counter_type==2:
            nr_events = self.move_counter
        elif self.end_pause_counter_type==3:
            nr_events = self.idle_counter
        elif self.end_pause_counter_type==4:
            now = pygame.time.get_ticks()
            nr_events = (now - self.time_recording_start)/1000
        return nr_events

    
    def change_spot(self):
        now = pygame.time.get_ticks()
        if now > self.yellow_until:
            self.yellow_on = False
            self.yellow_until = float('infinity')
        identifier = str()
        if self.yellow_on:
            identifier = identifier + 'yellow'
        self.this_spot_index = self.spot_states.index(identifier)
								
    
    def on_control_event(self,data):
        if self.on_trial:
            now = pygame.time.get_ticks()
            if u'accel' in data and data[u'accel']==1 and not self.already_moved:
                self.already_moved = True
            if u'cl_output' in data and data[u'cl_output']==-1 and not self.already_interrupted and not self.already_pressed and not self.already_moved and self.make_interruptions and self.bci_delayed_idle:
                if self.this_trial_type==2 and now > self.this_start_time + self.this_idle_waittime:
                    self.do_interruption()
                    self.idle_counter += 1
            if u'cl_output' in data and data[u'cl_output']==1 and not self.already_interrupted and not self.already_pressed and not self.already_moved and self.make_interruptions:
                if now > self.this_start_time + self.min_waittime:
                    if self.this_trial_type==1: # MOVE interruption
                        self.do_interruption()
                        self.move_counter += 1
                    if self.this_trial_type==2 and self.last_cl_output<1: # silent MOVE interruption, only at cout changes from -1 to 1
                        self.send_parallel_log(self.marker_base_interruption)
            if u'pedal' in data:
                if data[u'pedal']==1 and not self.already_pressed:
                    self.pedal_press()
            if u'cl_output' in data:
                self.last_cl_output = data[u'cl_output']
        if self.paused:
            if u'pedal' in data:
                if data[u'pedal']==1:
                    self.unpause()
        
    
    def on_keyboard_event(self):
        self.process_pygame_events()
        if self.keypressed:
            if self.on_trial and not self.already_pressed:
                self.keypressed = False
                self.pedal_press()
            if self.paused:
                self.keypressed = False
                self.unpause()
            if not self.on_trial:
                self.keypressed = False
                self.already_interrupted = False
        
        
    def this_trial(self):
        self.reset_trial_states()
        now = pygame.time.get_ticks()
        self.this_start_time = now
        if self.make_interruptions:
            self.this_trial_type = self.queue_trial.pop()
            self.this_idle_waittime = self.queue_waittime.pop()
            self.this_start_marker = self.marker_base_start + self.this_trial_type
            self.this_interruption_marker = self.marker_base_interruption + self.this_trial_type
            if self.this_trial_type==1:
                self.log('Trial %d | MOVE | Listening to classifier...' % (self.trial_counter+1))
            else:
                if self.bci_delayed_idle:
                    self.log('Trial %d | IDLE | Listening to classifier in %02.1f sec...' % (self.trial_counter+1,self.this_idle_waittime/1000))
                else:
                    self.log('Trial %d | IDLE | Interrupting in %02.1f sec...' % (self.trial_counter+1,self.this_idle_waittime/1000))
        else:
            self.this_start_marker = self.marker_base_start
            self.log('Trial %d | No interruptions...' % (self.trial_counter+1))
    
				
    def do_interruption(self):
        self.send_parallel_log(self.this_interruption_marker)
        now = pygame.time.get_ticks()
        self.already_interrupted = True
        winsound.Beep(1000,500) # winsound.Beep(frequency,duration in ms)
								
    
    def pedal_press(self):
        self.already_pressed = True
        now = pygame.time.get_ticks()
        self.time_trial_end = now + self.duration_spot_yellow
        if now < self.this_start_time + self.min_waittime: # i.e. if press occurs before interruption
            self.this_premature = True
            self.yellow_on = True 
            self.yellow_until = now + self.duration_spot_yellow
        else:
            self.pedalpress_counter += 1
            self.yellow_on = True
            self.yellow_until = now + self.duration_spot_yellow
        self.log('button press')


    def present_stimulus(self):
        self.screen.fill(self.background_color)
        if self.paused:
            self.render_text(self.pause_text)
        else:
            if self.on_trial:
                self.show_spot()
            else:
                self.draw_fixcross()
        pygame.display.update()


    def show_spot(self):
        this_spot = self.spot_image[self.this_spot_index]
        #image_size = this_spot.get_size()
        image_size = [85,85]
        self.screen.blit(this_spot,((self.screen_center[0]-image_size[0]/2),(self.screen_center[1]-image_size[1]/2)))


    def render_text(self, text):
        disp_text = self.font_text.render(text,0,self.text_color)
        textsize = disp_text.get_rect()
        self.screen.blit(disp_text, (self.screen_center[0] - textsize[2]/2, self.screen_center[1] - textsize[3]/2))
    
    
    def draw_fixcross(self):
        disp_text = self.font_char.render('+',0,self.char_color)
        textsize = disp_text.get_rect()
        self.screen.blit(disp_text, (self.screen_center[0] - textsize[2]/2, self.screen_center[1] - textsize[3]/2))
    
         
    def load_images(self):
        path = os.path.dirname(globals()["__file__"])
        self.spot_image = [None,None]
        for c, color in enumerate(self.spot_states):
            self.spot_image[c] = pygame.image.load(os.path.join(path, 'spot_' + color + '.png')).convert_alpha()
    

    def send_parallel_log(self, event):
        self.send_parallel(event)
        self.log(self.marker_identifier[event])
    
    
    def log(self,print_str):
        now = pygame.time.get_ticks()
        print '[%4.2f sec] %s' % (now/1000.0,print_str)


if __name__ == "__main__":
   fb = IntentionBeep()
   fb.on_init()
   fb.on_play()
